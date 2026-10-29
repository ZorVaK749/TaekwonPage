package tech.zvk.taekwonpage.content.persistence;

import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.repository.Repository;

public interface BodyToolRepository extends Repository<BodyTool, String> {
    @EntityGraph(attributePaths = "content")
    Optional<BodyTool> findById(String id);
}
