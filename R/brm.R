#' Fit Bayesian Generalized (Non-)Linear Multivariate Multilevel Models
#' 
#' Fit Bayesian generalized (non-)linear multivariate multilevel models 
#' using Stan for full Bayesian inference. A wide range of distributions 
#' and link functions are supported, allowing users to fit -- among others -- 
#' linear, robust linear, count data, survival, response times, ordinal, 
#' zero-inflated, hurdle, and even self-defined mixture models all in a 
#' multilevel context. Further modeling options include non-linear and 
#' smooth terms, auto-correlation structures, censored data, meta-analytic 
#' standard errors, and quite a few more. In addition, all parameters of the 
#' response distributions can be predicted in order to perform distributional 
#' regression. Prior specifications are flexible and explicitly encourage 
#' users to apply prior distributions that actually reflect their beliefs.
#' In addition, model fit can easily be assessed and compared with
#' posterior predictive checks and leave-one-out cross-validation.
#' 
#' @param formula An object of class \code{\link[stats:formula]{formula}},
#'   \code{\link{brmsformula}}, or \code{\link{mvbrmsformula}} (or one that can
#'   be coerced to that classes): A symbolic description of the model to be
#'   fitted. The details of model specification are explained in
#'   \code{\link{brmsformula}}.
#' @param data An object of class \code{data.frame} (or one that can be coerced
#'   to that class) containing data of all variables used in the model.
#' @param family A description of the response distribution and link function to
#'   be used in the model. This can be a family function, a call to a family
#'   function or a character string naming the family. Every family function has
#'   a \code{link} argument allowing to specify the link function to be applied
#'   on the response variable. If not specified, default links are used. For
#'   details of supported families see \code{\link{brmsfamily}}. By default, a
#'   linear \code{gaussian} model is applied. In multivariate models,
#'   \code{family} might also be a list of families.
#' @param prior One or more \code{brmsprior} objects created by
#'   \code{\link{set_prior}} or related functions and combined using the
#'   \code{c} method or the \code{+} operator. See also  \code{\link{get_prior}}
#'   for more help.
#' @param autocor An optional \code{\link{cor_brms}} object describing the
#'   correlation structure within the response variable (i.e., the
#'   'autocorrelation'). See the documentation of \code{\link{cor_brms}} for a
#'   description of the available correlation structures. Defaults to
#'   \code{NULL}, corresponding to no correlations. In multivariate models,
#'   \code{autocor} might also be a list of autocorrelation structures.
#' @param sparse Logical; indicates whether the population-level design matrices
#'   should be treated as sparse (defaults to \code{FALSE}). For design matrices
#'   with many zeros, this can considerably reduce required memory. Sampling
#'   speed is currently not improved or even slightly decreased.
#' @param cov_ranef A list of matrices that are proportional to the (within)
#'   covariance structure of the group-level effects. The names of the matrices
#'   should correspond to columns in \code{data} that are used as grouping
#'   factors. All levels of the grouping factor should appear as rownames of the
#'   corresponding matrix. This argument can be used, among others to model
#'   pedigrees and phylogenetic effects. See
#'   \code{vignette("brms_phylogenetics")} for more details.
#' @param save_ranef A flag to indicate if group-level effects for each level of
#'   the grouping factor(s) should be saved (default is \code{TRUE}). Set to
#'   \code{FALSE} to save memory. The argument has no impact on the model
#'   fitting itself.
#' @param save_mevars A flag to indicate if samples of latent noise-free
#'   variables obtained by using \code{me} and \code{mi} terms should be saved
#'   (default is \code{FALSE}). Saving these samples allows to better use
#'   methods such as \code{predict} with the latent variables but leads to very
#'   large \R objects even for models of moderate size and complexity.
#' @param save_all_pars A flag to indicate if samples from all variables defined
#'   in Stan's \code{parameters} block should be saved (default is
#'   \code{FALSE}). Saving these samples is required in order to apply the
#'   methods \code{bridge_sampler}, \code{bayes_factor}, and \code{post_prob}.
#' @param sample_prior Indicate if samples from all specified proper priors
#'   should be drawn additionally to the posterior samples (defaults to
#'   \code{"no"}). Among others, these samples can be used to calculate Bayes
#'   factors for point hypotheses via \code{\link{hypothesis}}. If set to
#'   \code{"only"}, samples are drawn solely from the priors ignoring the
#'   likelihood, which allows among others to generate samples from the prior
#'   predictive distribution. In this case, all parameters must have proper
#'   priors.
#' @param knots Optional list containing user specified knot values to be used
#'   for basis construction of smoothing terms. See
#'   \code{\link[mgcv:gamm]{gamm}} for more details.
#' @param stanvars An optional \code{stanvars} object generated by function
#'   \code{\link{stanvar}} to define additional variables for use in
#'   \pkg{Stan}'s program blocks.
#' @param stan_funs (Deprecated) An optional character string containing
#'   self-defined  \pkg{Stan} functions, which will be included in the functions
#'   block of the generated \pkg{Stan} code. It is now recommended to use the
#'   \code{stanvars} argument for this purpose, instead.
#' @param fit An instance of S3 class \code{brmsfit} derived from a previous
#'   fit; defaults to \code{NA}. If \code{fit} is of class \code{brmsfit}, the
#'   compiled model associated with the fitted result is re-used and all
#'   arguments modifying the model code or data are ignored. It is not
#'   recommended to use this argument directly, but to call the
#'   \code{\link[brms:update.brmsfit]{update}} method, instead.
#' @param inits Either \code{"random"} or \code{"0"}. If inits is
#'   \code{"random"} (the default), Stan will randomly generate initial values
#'   for parameters. If it is \code{"0"}, all parameters are initialized to
#'   zero. This option is sometimes useful for certain families, as it happens
#'   that default (\code{"random"}) inits cause samples to be essentially
#'   constant. Generally, setting \code{inits = "0"} is worth a try, if chains
#'   do not behave well. Alternatively, \code{inits} can be a list of lists
#'   containing the initial values, or a function (or function name) generating
#'   initial values. The latter options are mainly implemented for internal
#'   testing.
#' @param chains Number of Markov chains (defaults to 4).
#' @param iter Number of total iterations per chain (including warmup; defaults
#'   to 2000).
#' @param warmup A positive integer specifying number of warmup (aka burnin)
#'   iterations. This also specifies the number of iterations used for stepsize
#'   adaptation, so warmup samples should not be used for inference. The number
#'   of warmup should not be larger than \code{iter} and the default is
#'   \code{iter/2}.
#' @param thin Thinning rate. Must be a positive integer. Set \code{thin > 1} to
#'   save memory and computation time if \code{iter} is large.
#' @param cores Number of cores to use when executing the chains in parallel,
#'   which defaults to 1 but we recommend setting the \code{mc.cores} option to
#'   be as many processors as the hardware and RAM allow (up to the number of
#'   chains). For non-Windows OS in non-interactive \R sessions, forking is used
#'   instead of PSOCK clusters.
#' @param algorithm Character string indicating the estimation approach to use.
#'   Can be \code{"sampling"} for MCMC (the default), \code{"meanfield"} for
#'   variational inference with independent normal distributions, or
#'   \code{"fullrank"} for variational inference with a multivariate normal
#'   distribution.
#' @param control A named \code{list} of parameters to control the sampler's
#'   behavior. It defaults to \code{NULL} so all the default values are used.
#'   The most important control parameters are discussed in the 'Details'
#'   section below. For a comprehensive overview see
#'   \code{\link[rstan:stan]{stan}}.
#' @param future Logical; If \code{TRUE}, the \pkg{\link[future:future]{future}}
#'   package is used for parallel execution of the chains and argument
#'   \code{cores} will be ignored. Can be set globally for the current \R
#'   session via the \code{future} option. The execution type is controlled via
#'   \code{\link[future:plan]{plan}} (see the examples section below).
#' @param silent logical; If \code{TRUE} (the default), most of the
#'   informational messages of compiler and sampler are suppressed. The actual
#'   sampling progress is still printed. Set \code{refresh = 0} to turn this off
#'   as well. To stop Stan from opening additional progress bars, set
#'   \code{open_progress = FALSE}.
#' @param seed The seed for random number generation to make results
#'   reproducible. If \code{NA} (the default), \pkg{Stan} will set the seed
#'   randomly.
#' @param save_model Either \code{NULL} or a character string. In the latter
#'   case, the model's Stan code is saved via \code{\link{cat}} in a text file
#'   named after the string supplied in \code{save_model}.
#' @param file Either \code{NULL} or a character string. In the latter case, the
#'   fitted model object is saved via \code{\link{saveRDS}} in a file named
#'   after the string supplied in \code{file}. The \code{.rds} extension is
#'   added automatically. If the file already exists, \code{brm} will load and
#'   return the saved model object instead of refitting the model. As existing
#'   files won't be overwritten, you have to manually remove the file in order
#'   to refit and save the model under an existing file name. The file name
#'   is stored in the \code{brmsfit} object for later usage.
#' @param stan_model_args A \code{list} of further arguments passed to
#'   \code{\link[rstan:stan_model]{stan_model}}.
#' @param save_dso Logical, defaulting to \code{TRUE}, indicating whether the
#'   dynamic shared object (DSO) compiled from the C++ code for the model will
#'   be saved or not. If \code{TRUE}, we can draw samples from the same model in
#'   another \R session using the saved DSO (i.e., without compiling the C++
#'   code again).
#' @param ... Further arguments passed to Stan that is to
#'   \code{\link[rstan:sampling]{sampling}} or \code{\link[rstan:vb]{vb}}.
#' 
#' @return An object of class \code{brmsfit}, which contains the posterior
#'   samples along with many other useful information about the model. Use
#'   \code{methods(class = "brmsfit")} for an overview on available methods.
#'  
#' @author Paul-Christian Buerkner \email{paul.buerkner@@gmail.com}
#'
#' @details Fit a generalized (non-)linear multivariate multilevel model via
#'   full Bayesian inference using Stan. A general overview is provided in the
#'   vignettes \code{vignette("brms_overview")} and
#'   \code{vignette("brms_multilevel")}. For a full list of available vignettes
#'   see \code{vignette(package = "brms")}.
#'
#'   \bold{Formula syntax of brms models}
#'
#'   Details of the formula syntax applied in \pkg{brms} can be found in
#'   \code{\link{brmsformula}}.
#'
#'   \bold{Families and link functions}
#'
#'   Details of families supported by \pkg{brms} can be found in
#'   \code{\link{brmsfamily}}.
#'
#'   \bold{Prior distributions}
#'
#'   Priors should be specified using the
#'   \code{\link[brms:set_prior]{set_prior}} function. Its documentation
#'   contains detailed information on how to correctly specify priors. To find
#'   out on which parameters or parameter classes priors can be defined, use
#'   \code{\link[brms:get_prior]{get_prior}}. Default priors are chosen to be
#'   non or very weakly informative so that their influence on the results will
#'   be negligible and you usually don't have to worry about them. However,
#'   after getting more familiar with Bayesian statistics, I recommend you to
#'   start thinking about reasonable informative priors for your model
#'   parameters: Nearly always, there is at least some prior information
#'   available that can be used to improve your inference.
#'
#'   \bold{Adjusting the sampling behavior of \pkg{Stan}}
#'
#'   In addition to choosing the number of iterations, warmup samples, and
#'   chains, users can control the behavior of the NUTS sampler, by using the
#'   \code{control} argument. The most important reason to use \code{control} is
#'   to decrease (or eliminate at best) the number of divergent transitions that
#'   cause a bias in the obtained posterior samples. Whenever you see the
#'   warning "There were x divergent transitions after warmup." you should
#'   really think about increasing \code{adapt_delta}. To do this, write
#'   \code{control = list(adapt_delta = <x>)}, where \code{<x>} should usually
#'   be value between \code{0.8} (current default) and \code{1}. Increasing
#'   \code{adapt_delta} will slow down the sampler but will decrease the number
#'   of divergent transitions threatening the validity of your posterior
#'   samples.
#'
#'   Another problem arises when the depth of the tree being evaluated in each
#'   iteration is exceeded. This is less common than having divergent
#'   transitions, but may also bias the posterior samples. When it happens,
#'   \pkg{Stan} will throw out a warning suggesting to increase
#'   \code{max_treedepth}, which can be accomplished by writing \code{control =
#'   list(max_treedepth = <x>)} with a positive integer \code{<x>} that should
#'   usually be larger than the current default of \code{10}. For more details
#'   on the \code{control} argument see \code{\link[rstan:stan]{stan}}.
#'
#' @references Paul-Christian Buerkner (2017). brms: An R Package for Bayesian
#' Multilevel Models Using Stan. Journal of Statistical Software, 80(1), 1-28.
#' doi:10.18637/jss.v080.i01
#'
#' Paul-Christian Buerkner (in review). Advanced Bayesian Multilevel Modeling
#' with the R Package brms. arXiv preprint.
#'
#' @seealso \code{\link{brms}}, \code{\link{brmsformula}},
#' \code{\link{brmsfamily}}, \code{\link{brmsfit}}
#'
#' @examples
#' \dontrun{
#' # Poisson regression for the number of seizures in epileptic patients
#' # using student_t priors for population-level effects
#' # and half cauchy priors for standard deviations of group-level effects
#' bprior1 <- prior(student_t(5,0,10), class = b) +
#'   prior(cauchy(0,2), class = sd)
#' fit1 <- brm(count ~ log_Age_c + log_Base4_c * Trt + (1|patient),
#'             data = epilepsy, family = poisson(), prior = bprior1)
#'
#' # generate a summary of the results
#' summary(fit1)
#'
#' # plot the MCMC chains as well as the posterior distributions
#' plot(fit1, ask = FALSE)
#'
#' # predict responses based on the fitted model
#' head(predict(fit1))
#'
#' # plot marginal effects for each predictor
#' plot(marginal_effects(fit1), ask = FALSE)
#'
#' # investigate model fit
#' loo(fit1)
#' pp_check(fit1)
#'
#'
#' # Ordinal regression modeling patient's rating of inhaler instructions
#' # category specific effects are estimated for variable 'treat'
#' fit2 <- brm(rating ~ period + carry + cs(treat),
#'             data = inhaler, family = sratio("logit"),
#'             prior = set_prior("normal(0,5)"), chains = 2)
#' summary(fit2)
#' plot(fit2, ask = FALSE)
#' WAIC(fit2)
#'
#'
#' # Survival regression modeling the time between the first
#' # and second recurrence of an infection in kidney patients.
#' fit3 <- brm(time | cens(censored) ~ age * sex + disease + (1|patient),
#'             data = kidney, family = lognormal())
#' summary(fit3)
#' plot(fit3, ask = FALSE)
#' plot(marginal_effects(fit3), ask = FALSE)
#'
#'
#' # Probit regression using the binomial family
#' ntrials <- sample(1:10, 100, TRUE)
#' success <- rbinom(100, size = ntrials, prob = 0.4)
#' x <- rnorm(100)
#' data4 <- data.frame(ntrials, success, x)
#' fit4 <- brm(success | trials(ntrials) ~ x, data = data4,
#'             family = binomial("probit"))
#' summary(fit4)
#'
#'
#' # Simple non-linear gaussian model
#' x <- rnorm(100)
#' y <- rnorm(100, mean = 2 - 1.5^x, sd = 1)
#' data5 <- data.frame(x, y)
#' bprior5 <- prior(normal(0, 2), nlpar = a1) +
#'   prior(normal(0, 2), nlpar = a2)
#' fit5 <- brm(bf(y ~ a1 - a2^x, a1 + a2 ~ 1, nl = TRUE),
#'             data = data5, prior = bprior5)
#' summary(fit5)
#' plot(marginal_effects(fit5), ask = FALSE)
#'
#'
#' # Normal model with heterogeneous variances
#' data_het <- data.frame(
#'   y = c(rnorm(50), rnorm(50, 1, 2)),
#'   x = factor(rep(c("a", "b"), each = 50))
#' )
#' fit6 <- brm(bf(y ~ x, sigma ~ 0 + x), data = data_het)
#' summary(fit6)
#' plot(fit6)
#' marginal_effects(fit6)
#'
#' # extract estimated residual SDs of both groups
#' sigmas <- exp(posterior_samples(fit6, "^b_sigma_"))
#' ggplot(stack(sigmas), aes(values)) +
#'   geom_density(aes(fill = ind))
#'
#'
#' # Quantile regression predicting the 25%-quantile
#' fit7 <- brm(bf(y ~ x, quantile = 0.25), data = data_het,
#'             family = asym_laplace())
#' summary(fit7)
#' marginal_effects(fit7)
#'
#'
#' # use the future package for more flexible parallelization
#' library(future)
#' plan(multiprocess)
#' fit7 <- update(fit7, future = TRUE)
#' }
#'
#' @import Rcpp
#' @import parallel
#' @import methods
#' @import stats
#' @export
brm <- function(formula, data, family = gaussian(), prior = NULL, 
                autocor = NULL, cov_ranef = NULL, 
                sample_prior = c("no", "yes", "only"), 
                sparse = FALSE, knots = NULL, stanvars = NULL,
                stan_funs = NULL, fit = NA, save_ranef = TRUE, 
                save_mevars = FALSE, save_all_pars = FALSE, 
                inits = "random", chains = 4, iter = 2000, 
                warmup = floor(iter / 2), thin = 1,
                cores = getOption("mc.cores", 1L), control = NULL,
                algorithm = c("sampling", "meanfield", "fullrank"),
                future = getOption("future", FALSE), silent = TRUE, 
                seed = NA, save_model = NULL, stan_model_args = list(),
                save_dso = TRUE, file = NULL, ...) {
  
  if (!is.null(file)) {
    # optionally load saved model object
    file <- paste0(as_one_character(file), ".rds")
    x <- suppressWarnings(try(readRDS(file), silent = TRUE))
    if (!is(x, "try-error")) {
      if (!is.brmsfit(x)) {
        stop2("Object loaded via 'file' is not of class 'brmsfit'.")
      }
      x$file <- file
      return(x)
    }
  }
  
  # validate arguments later passed to Stan
  dots <- list(...)
  testmode <- isTRUE(dots$testmode)
  dots$testmode <- NULL
  algorithm <- match.arg(algorithm)
  silent <- as_one_logical(silent)
  future <- as_one_logical(future)
  iter <- as_one_numeric(iter)
  warmup <- as_one_numeric(warmup)
  thin <- as_one_numeric(thin)
  chains <- as_one_numeric(chains)
  cores <- as_one_numeric(cores)
  seed <- as_one_numeric(seed, allow_na = TRUE)
  if (is.character(inits) && !inits %in% c("random", "0")) {
    inits <- get(inits, mode = "function", envir = parent.frame())
  }
  
  if (is.brmsfit(fit)) {
    # re-use existing model
    x <- fit
    icnames <- c("loo", "waic", "kfold", "R2", "marglik")
    x[icnames] <- list(NULL)
    sdata <- standata(x)
    x$fit <- rstan::get_stanmodel(x$fit)
  } else {  
    # build new model
    formula <- validate_formula(
      formula, data = data, family = family, autocor = autocor
    )
    family <- get_element(formula, "family")
    autocor <- get_element(formula, "autocor")
    bterms <- parse_bf(formula)
    if (is.null(dots$data.name)) {
      data.name <- substr(collapse(deparse(substitute(data))), 1, 50)
    } else {
      data.name <- dots$data.name
      dots$data.name <- NULL
    }
    data <- update_data(data, bterms = bterms)
    prior <- check_prior(
      prior, formula, data = data, sparse = sparse,
      sample_prior = sample_prior, warn = FALSE
    )
    # initialize S3 object
    x <- brmsfit(
      formula = formula, family = family, data = data, 
      data.name = data.name, prior = prior, 
      autocor = autocor, cov_ranef = cov_ranef, 
      stanvars = stanvars, stan_funs = stan_funs,
      algorithm = algorithm
    )
    x$ranef <- tidy_ranef(bterms, data = x$data)  
    x$exclude <- exclude_pars(
      bterms, data = x$data, ranef = x$ranef, 
      save_ranef = save_ranef, save_mevars = save_mevars,
      save_all_pars = save_all_pars
    )
    x$model <- make_stancode(
      formula, data = data, prior = prior, 
      sparse = sparse, cov_ranef = cov_ranef,
      sample_prior = sample_prior, knots = knots, 
      stanvars = stanvars, stan_funs = stan_funs, 
      save_model = save_model
    )
    # generate Stan data before compiling the model to avoid
    # unnecessary compilations in case of invalid data
    sdata <- make_standata(
      formula, data = data, prior = prior, 
      cov_ranef = cov_ranef, sample_prior = sample_prior,
      knots = knots, stanvars = stanvars
    )
    stopifnot(is.list(stan_model_args))
    silence_stan_model <- !length(stan_model_args)
    stan_model_args$model_code <- x$model
    if (!isTRUE(save_dso)) {
      warning2("'save_dso' is deprecated. Please use 'stan_model_args'.")
      stan_model_args$save_dso <- save_dso
    }
    message("Compiling the C++ model")
    x$fit <- eval_silent(
      do_call(rstan::stan_model, stan_model_args),
      silent = silence_stan_model, type = "message"
    )
  }
  
  args <- nlist(
    object = x$fit, data = sdata, pars = x$exclude, 
    include = FALSE, algorithm, iter, seed
  )
  args[names(dots)] <- dots
  message("Start sampling")
  if (args$algorithm == "sampling") {
    args$algorithm <- NULL
    c(args) <- nlist(
      init = inits, warmup, thin, control, 
      show_messages = !silent
    )
    if (future) {
      require_package("future")
      if (cores > 1L) {
        warning2("Argument 'cores' is ignored when using 'future'.")
      }
      args$chains <- 1L
      futures <- fits <- vector("list", chains)
      for (i in seq_len(chains)) {
        args$chain_id <- i
        if (is.list(inits)) {
          args$init <- inits[i]
        }
        futures[[i]] <- future::future(
          brms::do_call(rstan::sampling, args), 
          packages = "rstan"
        )
      }
      for (i in seq_len(chains)) {
        fits[[i]] <- future::value(futures[[i]]) 
      }
      x$fit <- rstan::sflist2stanfit(fits)
      rm(futures, fits)
    } else {
      c(args) <- nlist(chains, cores)
      x$fit <- do_call(rstan::sampling, args) 
    }
  } else {
    # vb does not support parallel execution
    x$fit <- do_call(rstan::vb, args)
  }
  if (!testmode) {
    x <- rename_pars(x)
  }
  if (!is.null(file)) {
    x$file <- file
    saveRDS(x, file = file)
  }
  x
}
