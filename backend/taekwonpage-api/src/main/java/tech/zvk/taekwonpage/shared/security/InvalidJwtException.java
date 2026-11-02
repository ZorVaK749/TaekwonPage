package tech.zvk.taekwonpage.shared.security;

// Rejected token: malformed, forged, expired or from another issuer. Never
// mapped to a client-visible reason.
public class InvalidJwtException extends RuntimeException {
    public InvalidJwtException(String message) {
        super(message);
    }
}
