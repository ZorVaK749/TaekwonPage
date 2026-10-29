package tech.zvk.taekwonpage.content.persistence;

import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.repository.Repository;

public interface VocabularyRepository extends Repository<Vocabulary, String> {
    @EntityGraph(attributePaths = "content")
    Optional<Vocabulary> findById(String id);
}
