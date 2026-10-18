package tech.zvk.taekwonpage.content.persistence;

import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.repository.Repository;

public interface PositionRepository extends Repository<Position, String> {
    @EntityGraph(attributePaths = "content")
    Optional<Position> findById(String id);
}
