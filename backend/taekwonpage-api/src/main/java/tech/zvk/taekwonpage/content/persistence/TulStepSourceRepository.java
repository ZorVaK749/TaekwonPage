package tech.zvk.taekwonpage.content.persistence;

import java.util.List;
import org.springframework.data.repository.Repository;

public interface TulStepSourceRepository extends Repository<TulStepSource, TulStepSourceKey> {
    List<TulStepSource> findByTulIdOrderByStepNumberAscCitationIdAsc(String tulId);
}
