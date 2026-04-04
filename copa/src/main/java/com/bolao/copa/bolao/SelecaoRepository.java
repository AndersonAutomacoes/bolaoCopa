package com.bolao.copa.bolao;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SelecaoRepository extends JpaRepository<Selecao, Long> {

    Optional<Selecao> findByNomeIgnoreCase(String nome);

    boolean existsByNomeIgnoreCase(String nome);
}
