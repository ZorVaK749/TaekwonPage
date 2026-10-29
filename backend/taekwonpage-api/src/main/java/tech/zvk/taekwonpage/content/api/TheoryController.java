package tech.zvk.taekwonpage.content.api;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import tech.zvk.taekwonpage.content.TheoryService;
import tech.zvk.taekwonpage.shared.ids.CanonicalIds;

// Intentionally unreachable over HTTP until authentication/grade access is implemented.
@RestController
@RequestMapping("/api/v1/theory")
public class TheoryController {
    private final TheoryService theory;

    public TheoryController(TheoryService theory) {
        this.theory = theory;
    }

    @GetMapping("/{id}")
    public ResponseEntity<TheoryResponse> findById(@PathVariable String id) {
        if (!CanonicalIds.isValid(id)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST);
        }
        return ResponseEntity.of(theory.findById(id));
    }
}
