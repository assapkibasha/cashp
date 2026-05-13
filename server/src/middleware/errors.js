export function notFound(_req, res) {
  res.status(404).json({ error: 'Route not found' });
}

export function errorHandler(error, _req, res, _next) {
  if (error?.issues) {
    return res.status(400).json({ error: 'Invalid request', details: error.issues });
  }

  if (error?.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'Invalid JSON body' });
  }

  if (error?.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({ error: 'Record already exists' });
  }

  console.error(error);
  return res.status(500).json({ error: 'Internal server error' });
}
