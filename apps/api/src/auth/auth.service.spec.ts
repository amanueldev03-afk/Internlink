import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { validate } from 'class-validator';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { RegisterDto } from './dto/register.dto';

describe('AuthService', () => {
  const users = {
    findByEmail: jest.fn(),
    createStudentSafely: jest.fn(),
    toSafeUser: jest.fn((user: any) => ({ id: user.id, email: user.email, roles: user.roles })),
  };
  const jwt = { signAsync: jest.fn() };
  const config = { get: jest.fn(() => '1d') };
  const service = new AuthService(
    users as unknown as UsersService,
    jwt as unknown as JwtService,
    config as any,
  );

  beforeEach(() => jest.clearAllMocks());

  it('registers with an Argon2id hash and the fixed STUDENT role', async () => {
    users.findByEmail.mockResolvedValue(null);
    users.createStudentSafely.mockImplementation(async (data: any) => ({
      id: 'u1', email: data.email, roles: [{ role: { name: 'STUDENT' } }], ...data,
    }));
    const result = await service.register({
      email: ' New@Example.com ', password: 'a-strong-password', firstName: 'New', lastName: 'User',
    });
    const createData = users.createStudentSafely.mock.calls[0][0];
    expect(createData.email).toBe('new@example.com');
    expect(await argon2.verify(createData.passwordHash, 'a-strong-password')).toBe(true);
    expect(result).not.toHaveProperty('passwordHash');
    expect(result.roles).toEqual([{ role: { name: 'STUDENT' } }]);
    expect(users.createStudentSafely).toHaveBeenCalledTimes(1);
  });

  it('rejects duplicate email addresses', async () => {
    users.findByEmail.mockResolvedValue({ id: 'existing' });
    await expect(service.register({ email: 'a@example.com', password: 'password', firstName: 'A', lastName: 'B' })).rejects.toBeInstanceOf(ConflictException);
  });

  it('rejects invalid registration data and extra role fields', async () => {
    const dto = Object.assign(new RegisterDto(), {
      email: 'not-an-email', password: 'short', firstName: '', lastName: 'User', role: 'SYSTEM_ADMIN',
    });
    const errors = await validate(dto, { whitelist: true, forbidNonWhitelisted: true });
    expect(errors.length).toBeGreaterThan(0);
    expect(errors.some((error) => error.property === 'role')).toBe(true);
  });

  it('rejects incorrect passwords and unknown email addresses safely', async () => {
    users.findByEmail.mockResolvedValue({ passwordHash: await argon2.hash('correct-password'), isActive: true, status: 'ACTIVE' });
    await expect(service.login({ email: 'a@example.com', password: 'incorrect' })).rejects.toBeInstanceOf(UnauthorizedException);
    users.findByEmail.mockResolvedValue(null);
    await expect(service.login({ email: 'missing@example.com', password: 'incorrect' })).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('returns a signed JWT and safe user on successful login', async () => {
    const passwordHash = await argon2.hash('correct-password');
    const user = { id: 'u1', email: 'a@example.com', passwordHash, isActive: true, status: 'ACTIVE', roles: [] };
    users.findByEmail.mockResolvedValue(user);
    jwt.signAsync.mockResolvedValue('signed-token');
    await expect(service.login({ email: user.email, password: 'correct-password' })).resolves.toMatchObject({
      accessToken: 'signed-token', tokenType: 'Bearer', user: { id: 'u1' },
    });
  });

  it('validates JWT signatures and expiration', async () => {
    const tokens = new JwtService({ secret: 'a-test-secret-that-is-at-least-32-chars' });
    const token = await tokens.signAsync({ sub: 'u1' }, { expiresIn: '1h' });
    await expect(tokens.verifyAsync(token)).resolves.toMatchObject({ sub: 'u1' });
    await expect(tokens.verifyAsync(`${token.slice(0, -1)}x`)).rejects.toThrow();
    const expired = await tokens.signAsync({ sub: 'u1' }, { expiresIn: -1 });
    await expect(tokens.verifyAsync(expired)).rejects.toThrow();
  });
});
