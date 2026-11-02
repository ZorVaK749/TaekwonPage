package tech.zvk.taekwonpage.auth;

import java.util.LinkedHashSet;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.security.crypto.password.PasswordEncoder;
import tech.zvk.taekwonpage.identity.AppUserRepository;
import tech.zvk.taekwonpage.identity.Role;
import tech.zvk.taekwonpage.shared.security.AuthenticatedUser;

// Credential check against the local account table. Unknown users, wrong
// passwords and disabled accounts all perform one bcrypt verification and
// return the same result. This reduces timing leaks, not a constant-time DB guarantee.
@Service
public class AuthService {
    private final AppUserRepository users;
    private final PasswordEncoder passwords;
    private final String unmatchedHash;

    public AuthService(AppUserRepository users, PasswordEncoder passwords) {
        this.users = users;
        this.passwords = passwords;
        this.unmatchedHash = passwords.encode(UUID.randomUUID().toString());
    }

    @Transactional(readOnly = true)
    public Optional<AuthenticatedUser> authenticate(String username, String password) {
        var user = users.findByUsername(username).orElse(null);
        String stored = user != null && user.enabled() ? user.passwordHash() : unmatchedHash;
        boolean matches = passwords.matches(password, stored);
        if (user == null || !user.enabled() || !matches) {
            return Optional.empty();
        }
        var roles = user.roles().stream().map(Role::name)
            .collect(Collectors.toCollection(LinkedHashSet::new));
        return Optional.of(new AuthenticatedUser(user.id(), user.username(), roles));
    }
}
