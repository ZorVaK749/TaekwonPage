package tech.zvk.taekwonpage.auth;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import tech.zvk.taekwonpage.shared.security.AuthenticatedUser;

// Reads the identity carried by the token. Grants nothing else: content
// routes keep answering 403 until C2 opens them.
@RestController
@RequestMapping("/api/v1")
public class MeController {
    @GetMapping("/me")
    public ResponseEntity<MeResponse> me(Authentication authentication) {
        if (authentication == null || !(authentication.getPrincipal() instanceof AuthenticatedUser user)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
        }
        return ResponseEntity.ok(new MeResponse(user.id(), user.username(),
            user.roles().stream().sorted().toList()));
    }
}
