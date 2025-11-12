export function jsonResponse(body: unknown, init: ResponseInit = {}): Response {
  return new Response(JSON.stringify(body), {
    headers: { 'Content-Type': 'application/json', ...(init.headers ?? {}) },
    ...init,
  });
}

export async function requireJson<T>(request: Request): Promise<T> {
  try {
    return await request.json() as T;
  } catch (err) {
    throw new Error(`Invalid JSON payload: ${err}`);
  }
}
