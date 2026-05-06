import { Result$Ok, Result$Error, BitArray$BitArray } from "./gleam.mjs";
import { Order$Lt, Order$Eq, Order$Gt } from "../gleam_stdlib/gleam/order.mjs";
import { Endianness$isBigEndian, Signedness$isSigned } from "./bigi.mjs";

export function from(int) {
  return BigInt(int);
}

export function from_string(string) {
  try {
    return Result$Ok(BigInt(string));
  } catch {
    return Result$Error(undefined);
  }
}

export function from_bytes(bit_array, endianness, signedness) {
  if (bit_array.bitSize % 8 !== 0) {
    return Result$Error(undefined);
  }

  let value = 0n;

  // Read bytes as an unsigned integer value
  if (Endianness$isBigEndian(endianness)) {
    for (let i = 0; i < bit_array.byteSize; i++) {
      value = value * 256n + BigInt(bit_array.byteAt(i));
    }
  } else {
    for (let i = bit_array.byteSize - 1; i >= 0; i--) {
      value = value * 256n + BigInt(bit_array.byteAt(i));
    }
  }

  if (Signedness$isSigned(signedness)) {
    const byteSize = BigInt(bit_array.byteSize);

    const highBit = 2n ** (byteSize * 8n - 1n);

    // If the high bit is set and this is a signed integer, reinterpret as
    // two's complement
    if (value >= highBit) {
      value -= highBit * 2n;
    }
  }

  return Result$Ok(value);
}

export function to(bigint) {
  if (bigint > Number.MAX_SAFE_INTEGER || bigint < Number.MIN_SAFE_INTEGER) {
    return Result$Error(undefined);
  } else {
    return Result$Ok(Number(bigint));
  }
}

export function to_string(bigint) {
  return bigint.toString();
}

export function to_bytes(bigint, endianness, signedness, byte_count) {
  const bit_count = BigInt(byte_count * 8);

  if (bit_count < 8n) {
    return Result$Error(undefined);
  }

  let range_min = 0n;
  let range_max = 0n;

  // Error if the value is out of range for the available bits
  if (Signedness$isSigned(signedness)) {
    range_min = -(2n ** (bit_count - 1n));
    range_max = -range_min - 1n;
  } else {
    range_max = 2n ** bit_count - 1n;
  }

  if (bigint < range_min || bigint > range_max) {
    return Result$Error(undefined);
  }

  // Convert negative number to two's complement representation
  if (bigint < 0) {
    bigint = (1n << bit_count) + bigint;
  }

  const byteArray = new Uint8Array(byte_count);

  if (Endianness$isBigEndian(endianness)) {
    for (let i = byteArray.length - 1; i >= 0; i--) {
      const byte = bigint % 256n;
      byteArray[i] = Number(byte);
      bigint = (bigint - byte) / 256n;
    }
  } else {
    for (let i = 0; i < byteArray.length; i++) {
      const byte = bigint % 256n;
      byteArray[i] = Number(byte);
      bigint = (bigint - byte) / 256n;
    }
  }

  return Result$Ok(BitArray$BitArray(byteArray));
}

export function zero() {
  return 0n;
}

export function one() {
  return 1n;
}

export function n_one() {
  return -1n;
}

export function ten() {
  return 10n;
}

export function compare(a, b) {
  if (a < b) {
    return Order$Lt();
  } else if (a > b) {
    return Order$Gt();
  } else {
    return Order$Eq();
  }
}

export function absolute(bigint) {
  if (bigint < 0) {
    return -bigint;
  } else {
    return bigint;
  }
}

export function negate(bigint) {
  return -bigint;
}

export function add(a, b) {
  return a + b;
}

export function subtract(a, b) {
  return a - b;
}

export function multiply(a, b) {
  return a * b;
}

export function divide(a, b) {
  if (b === 0n) {
    return 0n;
  }

  return a / b;
}

export function divide_no_zero(a, b) {
  if (b === 0n) {
    return Result$Error(undefined);
  }

  return Result$Ok(divide(a, b));
}

export function remainder(a, b) {
  if (b === 0n) {
    return 0n;
  }

  return a % b;
}

export function remainder_no_zero(a, b) {
  if (b === 0n) {
    return Result$Error(undefined);
  }

  return Result$Ok(remainder(a, b));
}

export function modulo(a, b) {
  if (b === 0n) {
    return 0n;
  }

  return ((a % b) + b) % b;
}

export function modulo_no_zero(a, b) {
  if (b === 0n) {
    return Result$Error(undefined);
  }

  return Result$Ok(modulo(a, b));
}

export function power(a, b) {
  if (b < 0) {
    return Result$Error(undefined);
  }

  return Result$Ok(a ** b);
}

export function decode(dyn) {
  if (typeof dyn === "bigint") {
    return Result$Ok(dyn);
  } else {
    return Result$Error(0n);
  }
}

export function bitwise_and(a, b) {
  return a & b;
}

export function bitwise_exclusive_or(a, b) {
  return a ^ b;
}

export function bitwise_not(a) {
  return ~a;
}

export function bitwise_or(a, b) {
  return a | b;
}

export function bitwise_shift_left(a, b) {
  return a << BigInt(b);
}

export function bitwise_shift_right(a, b) {
  return a >> BigInt(b);
}

export function from_base2(str) {
  try {
    return Result$Ok(BigInt("0b" + str));
  } catch {
    return Result$Error(undefined);
  }
}

export function from_base8(str) {
  try {
    return Result$Ok(BigInt("0o" + str));
  } catch {
    return Result$Error(undefined);
  }
}

export function from_base16(str) {
  try {
    return Result$Ok(BigInt("0x" + str));
  } catch {
    return Result$Error(undefined);
  }
}

export function to_base2(int) {
  return int.toString(2);
}

export function to_base8(int) {
  return int.toString(8);
}

export function to_base16(int) {
  return int.toString(16);
}
