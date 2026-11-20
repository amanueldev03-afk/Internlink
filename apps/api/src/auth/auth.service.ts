import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService, JwtSignOptions } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { UsersService } from '../users/users.service';

const DUMMY_PASSWORD_HASH =
  '$argon2id$v=19$m=19456,t=2,p=1$VLBVfzcnuZioOKHZK4MPrg$aiTg2r6niVAev53gZ1heL50fZGcW1HkXez/E1K2m7pc';

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UsersService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async register(input: RegisterDto) {
    const email = input.email.trim().toLowerCase();
    if (await this.users.findByEmail(email)) throw new ConflictException('Account already exists');
    const passwordHash = await argon2.hash(input.password, {
      type: argon2.argon2id,
      memoryCost: 19456,
      timeCost: 2,
      parallelism: 1,
    });
    const user = await this.users.createStudentSafely({
      email,
      passwordHash,
      firstName: input.firstName.trim(),
      lastName: input.lastName.trim(),
      ...(input.phone ? { phone: input.phone.trim() } : {}),
    });
    if (!user) throw new ConflictException('Account already exists');
    return this.users.toSafeUser(user);
  }

  async login(input: LoginDto) {
    const user = await this.users.findByEmail(input.email.trim().toLowerCase());
    const validPassword = user
      ? await argon2.verify(user.passwordHash, input.password).catch(() => false)
      : await argon2
          .verify(
          DUMMY_PASSWORD_HASH,
            input.password,
          )
          .catch(() => false);
    if (!user || !validPassword || !user.isActive || user.status !== 'ACTIVE') {
      throw new UnauthorizedException('Invalid email or password');
    }
    const safeUser = this.users.toSafeUser(user);
    const accessToken = await this.jwt.signAsync(
      { sub: user.id, email: user.email },
      {
        expiresIn: (this.config.get<string>('jwt.expiresIn') ?? '1d') as JwtSignOptions['expiresIn'],
      },
    );
    return { accessToken, tokenType: 'Bearer', user: safeUser };
  }
}
