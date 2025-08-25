//
//  RequestIDMiddleware.swift
//  Vector2FA
//
//  Middleware that ensures every request has a request ID.
//  - Injects/propagates `X-Request-ID` header
//  - Attaches it to logs as `req-id` metadata
//  - Returns it in the response headers
//

import Vapor

struct RequestIDMiddleware: AsyncMiddleware {
    func respond(to req: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // Prefer client-provided header, otherwise generate one.
        let id = req.headers.first(name: "X-Request-ID") ?? UUID().uuidString

        // Stamp it into the logger metadata.
        req.logger[metadataKey: "req-id"] = .string(id)

        // Continue down the chain.
        var res = try await next.respond(to: req)

        // Add/overwrite header so client sees the ID we used.
        res.headers.replaceOrAdd(name: "X-Request-ID", value: id)
        return res
    }
}
