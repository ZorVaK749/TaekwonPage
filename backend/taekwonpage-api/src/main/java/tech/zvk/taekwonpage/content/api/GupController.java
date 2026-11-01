package tech.zvk.taekwonpage.content.api;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import tech.zvk.taekwonpage.content.GupService;

// Intentionally unreachable over HTTP until authentication/grade access is implemented.
@RestController
@RequestMapping("/api/v1/gups")
public class GupController {
    private final GupService gups;

    public GupController(GupService gups) {
        this.gups = gups;
    }

    @GetMapping("/{gup}")
    public ResponseEntity<GupResponse> findByNumber(@PathVariable Integer gup) {
        if (gup == null || gup < 1 || gup > 10) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST);
        }
        return ResponseEntity.of(gups.findByNumber(gup));
    }
}
