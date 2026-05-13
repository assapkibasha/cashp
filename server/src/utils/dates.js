export function toDateOnly(value = new Date()) {
  return new Date(value).toISOString().slice(0, 10);
}

export function fromSqlDate(value) {
  if (!value) return null;
  return new Date(value).toISOString();
}
