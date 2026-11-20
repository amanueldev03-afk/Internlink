import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { UsersService } from '../../users/users.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(config: ConfigService, private readonly users: UsersService) {
    const secret = config.get<string>('jwt.secret');
    if (!secret) throw new Error('JWT_SECRET is required');
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
    });
  }

  async validate(payload: { sub?: string }) {
    if (!payload.sub) throw new UnauthorizedException();
    // Resolve by immutable user id without trusting identity data in the token.
    const found = await this.users.findById(payload.sub);
    if (!found || !found.isActive || found.status !== 'ACTIVE') {
      throw new UnauthorizedException();
    }
    return this.users.toSafeUser(found);
  }
}
