import { describe, expect, it } from '@jest/globals';
import { parsePort } from './configuration';

describe('parsePort', () => {
  it('uses the default port when PORT is unset', () => {
    expect(parsePort(undefined)).toBe(3001);
  });

  it('accepts an integer TCP port', () => {
    expect(parsePort('8080')).toBe(8080);
  });

  it.each(['', 'abc', '3.5', '0', '65536', '-1'])(
    'rejects invalid PORT value %j safely',
    (value) => {
      expect(() => parsePort(value)).toThrow('PORT must be an integer between 1 and 65535.');
      try {
        parsePort(value);
      } catch (error) {
        expect(error).toMatchObject({ code: 'INVALID_PORT' });
      }
    },
  );
});
