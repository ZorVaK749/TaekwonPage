package tech.zvk.taekwonpage.shared.security;

import java.util.Set;

// Authenticated identity carried as the security principal. Roles are the
// documented ROLE_* names; martial grade is intentionally absent here.
public record AuthenticatedUser(String id, String username, Set<String> roles) {
    public AuthenticatedUser {
        roles = Set.copyOf(roles);
    }
}
