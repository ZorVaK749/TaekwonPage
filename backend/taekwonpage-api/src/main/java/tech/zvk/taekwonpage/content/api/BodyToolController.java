package tech.zvk.taekwonpage.content.api;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import tech.zvk.taekwonpage.content.BodyToolService;
import tech.zvk.taekwonpage.shared.ids.CanonicalIds;

// Intentionally unreachable over HTTP until authentication/grade access is implemented.
@RestController
@RequestMapping("/api/v1/body-tools")
public class BodyToolController {
    private final BodyToolService tools;

    public BodyToolController(BodyToolService tools) {
        this.tools = tools;
    }

    @GetMapping("/{id}")
    public ResponseEntity<BodyToolResponse> findById(@PathVariable String id) {
        if (!CanonicalIds.isValid(id)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST);
        }
        return ResponseEntity.of(tools.findById(id));
    }
}
