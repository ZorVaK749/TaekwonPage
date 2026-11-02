package tech.zvk.taekwonpage.auth;

import java.nio.charset.StandardCharsets;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import tech.zvk.taekwonpage.shared.security.LocalJwtService;

// Only route that issues credentials. No registration here: provisioning waits
// for the grade/verification model (TKD-016/TKD-017) and no user is seeded.
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private static final String BEARER = "Bearer";

    private final AuthService auth;
    private final LocalJwtService jwt;

    public AuthController(AuthService auth, LocalJwtService jwt) {
        this.auth = auth;
        this.jwt = jwt;
    }

    @PostMapping("/login")
    public ResponseEntity<TokenResponse> login(@RequestBody(required = false) LoginRequest request) {
        if (request == null || !StringUtils.hasText(request.username()) || !StringUtils.hasText(request.password())
                || !request.username().matches("[A-Za-z0-9._-]{3,64}")
                || request.password().getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST);
        }
        var user = auth.authenticate(request.username(), request.password());
        if (user.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .header(HttpHeaders.WWW_AUTHENTICATE, BEARER)
                .build();
        }
        return ResponseEntity.ok(new TokenResponse(jwt.issue(user.get()), BEARER, jwt.ttlSeconds()));
    }
}
