package tech.zvk.taekwonpage.shared.security;

import java.util.Set;

// Verified claims of a locally issued token.
public record JwtClaims(String id, String username, Set<String> roles) {
    public JwtClaims {
        roles = Set.copyOf(roles);
    }
}
