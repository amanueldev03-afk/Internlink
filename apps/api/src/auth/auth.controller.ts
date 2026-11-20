import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@Controller('api/v1/auth')
@UsePipes(
  new ValidationPipe({
    whitelist: true,
    transform: true,
    forbidNonWhitelisted: true,
  }),
)
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  register(@Body() input: RegisterDto) {
    return this.auth.register(input);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() input: LoginDto) {
    return this.auth.login(input);
  }
}
