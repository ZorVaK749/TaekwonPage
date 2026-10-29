package tech.zvk.taekwonpage.content.persistence;

import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.repository.Repository;

public interface TulRepository extends Repository<Tul, String> {
    @EntityGraph(attributePaths = "content")
    Optional<Tul> findById(String id);
}
