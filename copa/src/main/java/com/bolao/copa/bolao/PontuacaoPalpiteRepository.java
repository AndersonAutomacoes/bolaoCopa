package com.bolao.copa.bolao;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PontuacaoPalpiteRepository extends JpaRepository<PontuacaoPalpite, Long> {

    Optional<PontuacaoPalpite> findByPalpite_Id(Long palpiteId);
}
