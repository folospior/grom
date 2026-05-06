import os from 'node:os';

export function name() {
  return os.type().toLowerCase();
}
