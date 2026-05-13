export function mysql2Uri(rawUrl, databaseName) {
  const url = new URL(rawUrl);
  url.searchParams.delete('ssl-mode');
  if (databaseName) {
    url.pathname = `/${databaseName}`;
  }
  return url.toString();
}
