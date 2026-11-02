package tech.zvk.taekwonpage.auth;

import com.fasterxml.jackson.annotation.JsonProperty;

// OAuth2-style field names; the token is a locally issued bearer credential,
// not an OAuth flow with refresh tokens.
public record TokenResponse(
    @JsonProperty("access_token") String accessToken,
    @JsonProperty("token_type") String tokenType,
    @JsonProperty("expires_in") long expiresIn) {
}
