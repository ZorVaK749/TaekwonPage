package tech.zvk.taekwonpage.content.api;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import tech.zvk.taekwonpage.content.VocabularyService;
import tech.zvk.taekwonpage.shared.ids.CanonicalIds;

// Intentionally unreachable over HTTP until authentication/grade access is implemented.
@RestController
@RequestMapping("/api/v1/vocabulary")
public class VocabularyController {
    private final VocabularyService vocabulary;

    public VocabularyController(VocabularyService vocabulary) {
        this.vocabulary = vocabulary;
    }

    @GetMapping("/{id}")
    public ResponseEntity<VocabularyResponse> findById(@PathVariable String id) {
        if (!CanonicalIds.isValid(id)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST);
        }
        return ResponseEntity.of(vocabulary.findById(id));
    }
}
