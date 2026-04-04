package com.bolao.copa.bolao;

/**
 * Regras do bolão: placar exato = 5 pts; acerto do resultado (vencedor/empate) = 3 pts; erro = 0.
 */
public final class PontuacaoRules {

    private PontuacaoRules() {
    }

    public record ScoreResult(int pontos, boolean acertoExato) {
    }

    /**
     * @param golsCasa   placar oficial casa
     * @param golsFora   placar oficial fora
     * @param palpiteCasa palpite casa
     * @param palpiteFora palpite fora
     */
    public static ScoreResult score(int golsCasa, int golsFora, int palpiteCasa, int palpiteFora) {
        if (palpiteCasa == golsCasa && palpiteFora == golsFora) {
            return new ScoreResult(5, true);
        }
        if (Integer.compare(palpiteCasa, palpiteFora) == Integer.compare(golsCasa, golsFora)) {
            return new ScoreResult(3, false);
        }
        return new ScoreResult(0, false);
    }
}
