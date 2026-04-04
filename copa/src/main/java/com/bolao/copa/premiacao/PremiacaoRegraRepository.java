package com.bolao.copa.premiacao;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PremiacaoRegraRepository extends JpaRepository<PremiacaoRegra, Long> {

    List<PremiacaoRegra> findByOwner_IdOrderByCreatedAtDesc(Long ownerId);
}
