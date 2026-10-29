package tech.zvk.taekwonpage.content.persistence;

import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.repository.Repository;

public interface TheoryContentRepository extends Repository<TheoryContent, String> {
    @EntityGraph(attributePaths = "content")
    Optional<TheoryContent> findById(String id);
}
