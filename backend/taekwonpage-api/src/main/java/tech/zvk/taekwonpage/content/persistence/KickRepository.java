package tech.zvk.taekwonpage.content.persistence;

import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.repository.Repository;

public interface KickRepository extends Repository<Kick, String> {
    @EntityGraph(attributePaths = "content")
    Optional<Kick> findById(String id);
}
