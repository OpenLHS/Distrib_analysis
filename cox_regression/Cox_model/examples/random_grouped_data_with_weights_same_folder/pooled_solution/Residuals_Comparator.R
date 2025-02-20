# Schoenfeld Residuals checker
scho <- residuals(res.cox, type = "schoenfeld", weighted = T)

index <- 6
r1 <- read.csv(paste0("SchoenfeldResiduals1_output_", index, ".csv"))
r2 <- read.csv(paste0("SchoenfeldResiduals2_output_", index, ".csv"))
r3 <- read.csv(paste0("SchoenfeldResiduals3_output_", index, ".csv"))

scho_dist <- rbind(r1,r2,r3)

head(scho[order(scho[,1]),])
head(scho_dist[order(scho_dist[,1]),])

tail(scho[order(scho[,1]),])
tail(scho_dist[order(scho_dist[,1]),])

colSums(scho)
colSums(scho_dist)

# Score Residuals checker
score <- residuals(res.cox, type = "score", weighted = T)

index <- 6
r1 <- read.csv(paste0("ScoreResiduals1_output_", index, ".csv"))
r2 <- read.csv(paste0("ScoreResiduals2_output_", index, ".csv"))
r3 <- read.csv(paste0("ScoreResiduals3_output_", index, ".csv"))

score_dist <- rbind(r1,r2,r3)

head(score[order(score[,1]),])
head(score_dist[order(score_dist[,1]),])

tail(score[order(score[,1]),])
tail(score_dist[order(score_dist[,1]),])

colSums(score_dist)
colSums(score)

# SE
res_dist <- read.csv(paste0("RobustSE_output_", index, ".csv"))

summary(res.cox)
res_dist


