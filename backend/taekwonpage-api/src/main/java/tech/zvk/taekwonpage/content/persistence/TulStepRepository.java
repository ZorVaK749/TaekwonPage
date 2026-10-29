package tech.zvk.taekwonpage.content.persistence;

import java.util.List;
import org.springframework.data.repository.Repository;

public interface TulStepRepository extends Repository<TulStep, TulStepKey> {
    List<TulStep> findByTulIdOrderByStepNumberAsc(String tulId);
}
