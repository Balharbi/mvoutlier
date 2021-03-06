mvoutlier.CoDa <- 
function (x, quan = 0.75, alpha = 0.025, col.quantile = c(0, 
    0.05, 0.1, 0.5, 0.9, 0.95, 1), symb.pch = c(3, 3, 16, 1, 
    1), symb.cex = c(1.5, 1, 0.5, 1, 1.5), adaptive = TRUE) 
{
    if (!is.matrix(x) && !is.data.frame(x)) 
        stop("x must be matrix or data.frame")
    if (ncol(x) < 3) 
        stop("x must have at least 3 compositional parts")
    Z <- pivotCoord(x)
    #V <- (-orthbasis(ncol(x))$V)
    V <- (orthbasis(ncol(x))$V)
    Zj <- matrix(NA, nrow = nrow(x), ncol = ncol(x))
    for (j in 1:ncol(x)) {
        Zj[, j] <- pivotCoord(cbind(x[, j], x[, -j]))[, 1]
    }
    dimnames(Zj)[[2]] <- names(x)
    rob <- covMcd(Z, alpha = quan)
    if (adaptive) {
        Zarw <- arw(Z, rob$center, rob$cov, alpha = alpha)
        if (Zarw$cn != Inf) {
            alpha1 <- sqrt(c(Zarw$cn, qchisq(c(0.75, 0.5, 0.25), 
                ncol(Z))))
        }
        else {
            alpha1 <- sqrt(qchisq(c(0.975, 0.75, 0.5, 0.25), 
                ncol(Z)))
        }
        rd2 <- mahalanobis(Z, center = Zarw$m, cov = Zarw$c)
    }
    else {
        cutoff <- qchisq(1 - alpha, ncol(Z))
        rd2 <- mahalanobis(Z, center = rob$center, cov = rob$cov)
        Zarw <- list(m = rob$center, c = rob$cov, cn = cutoff, 
            w = as.numeric(rd2 < cutoff))
        alpha1 <- sqrt(qchisq(c(0.975, 0.75, 0.5, 0.25), ncol(Z)))
    }
    rd <- sqrt(rd2)
    covobj <- list(center = Zarw$m, cov = Zarw$c, n.obs = length(rd), 
        mah = rd)
    Z.pca <- suppressWarnings(princomp(Z, covmat = covobj, cor = FALSE))
    pcaclr <- Z.pca
    eval <- eigen(Zarw$c)$values
    pcaclr$sdev <- sqrt(eval)
    pcaclr$scores <- Z.pca$scores
    pcaclr$loadings <- V %*% Z.pca$loadings
    dimnames(pcaclr$loadings)[[1]] <- names(x)
    pcaobj <- list(method = "robust", eigenvalues = eval, princompOutputClr = pcaclr)
    class(pcaobj) <- "pcaCoDa"
    Zcent <- scale(Zj, center = apply(Zj, 2, median), scale = FALSE)
    eucl <- apply(abs(Zcent), 1, median)
    out <- (!Zarw$w)
    lq <- length(col.quantile)
    colcol <- rev(rainbow(lq - 1, start = 0, end = 0.7))[as.integer(cut(eucl, 
        quantile(eucl, col.quantile, labels = 1:(lq - 1))))]
    colbw <- rev(gray(seq(from = 0.1, to = 0.9, length = lq - 
        1)))[as.integer(cut(eucl, quantile(eucl, col.quantile, 
        labels = 1:(lq - 1))))]
    pchvec <- rep(symb.pch[1], nrow(Zj))
    cexvec <- rep(symb.cex[1], nrow(Zj))
    if (length(symb.pch) == 5 & length(symb.cex) == 5) {
        lalpha <- length(alpha1)
        for (j in 1:(lalpha)) {
            pchvec[rd < alpha1[j]] <- symb.pch[j + 1]
            cexvec[rd < alpha1[j]] <- symb.cex[j + 1]
        }
    }
    mvoutlierCoDa <- list(ilrvariables = Zj, outliers = out, 
        pcaobj = pcaobj, colcol = colcol, colbw = colbw, pchvec = pchvec, 
        cexvec = cexvec)
    class(mvoutlierCoDa) <- "mvoutlierCoDa"
    return(mvoutlierCoDa)
}
