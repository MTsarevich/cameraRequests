import { normalizePhone } from "../src/phone";

describe("normalizePhone (Belarus)", () => {
  test("international +375 form", () => {
    expect(normalizePhone("+375 29 123-45-67")).toBe("+375291234567");
    expect(normalizePhone("+375291234567")).toBe("+375291234567");
  });

  test("375 without plus", () => {
    expect(normalizePhone("375 29 123 45 67")).toBe("+375291234567");
  });

  test("domestic long-distance 8 0XX form", () => {
    expect(normalizePhone("8 029 123-45-67")).toBe("+375291234567");
    expect(normalizePhone("80291234567")).toBe("+375291234567");
  });

  test("leading-zero form 0XX", () => {
    expect(normalizePhone("029 123-45-67")).toBe("+375291234567");
    expect(normalizePhone("0291234567")).toBe("+375291234567");
  });

  test("bare 9-digit operator code + number", () => {
    expect(normalizePhone("291234567")).toBe("+375291234567");
    expect(normalizePhone("33 123-45-67")).toBe("+375331234567");
  });

  test("empty / non-digit input returns empty", () => {
    expect(normalizePhone("")).toBe("");
    expect(normalizePhone("   ")).toBe("");
    expect(normalizePhone("abc")).toBe("");
  });

  test("unknown shape kept as international, not dropped", () => {
    expect(normalizePhone("+1 415 555 2671")).toBe("+14155552671");
  });
});
