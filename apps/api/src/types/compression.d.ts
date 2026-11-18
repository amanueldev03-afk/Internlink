declare module 'compression' {
  import type { RequestHandler } from 'express';
  const compression: () => RequestHandler;
  export default compression;
}
