#' @rdname ml_gradient_boosted_trees
#' @template roxlate-ml-predictor-params
#' @export
ml_gbt_regressor <- function(
  x,
  formula = NULL,
  max_iter = 20L,
  max_depth = 5L,
  step_size = 0.1,
  subsampling_rate = 1,
  min_instances_per_node = 1L,
  max_bins = 32L,
  min_info_gain = 0,
  loss_type = "squared",
  seed = NULL,
  checkpoint_interval = 10L,
  cache_node_ids = FALSE,
  max_memory_in_mb = 256L,
  features_col = "features",
  label_col = "label",
  prediction_col = "prediction",
  uid = random_string("gbt_regressor_"), ...
) {
  UseMethod("ml_gbt_regressor")
}

#' @export
ml_gbt_regressor.spark_connection <- function(
  x,
  formula = NULL,
  max_iter = 20L,
  max_depth = 5L,
  step_size = 0.1,
  subsampling_rate = 1,
  min_instances_per_node = 1L,
  max_bins = 32L,
  min_info_gain = 0,
  loss_type = "squared",
  seed = NULL,
  checkpoint_interval = 10L,
  cache_node_ids = FALSE,
  max_memory_in_mb = 256L,
  features_col = "features",
  label_col = "label",
  prediction_col = "prediction",
  uid = random_string("gbt_regressor_"), ...) {

  ml_ratify_args()

  class <- "org.apache.spark.ml.regression.GBTRegressor"

  jobj <- ml_new_predictor(x, class, uid, features_col,
                           label_col, prediction_col) %>%
    invoke("setCheckpointInterval", checkpoint_interval) %>%
    invoke("setMaxBins", max_bins) %>%
    invoke("setMaxDepth", max_depth) %>%
    invoke("setMinInfoGain", min_info_gain) %>%
    invoke("setMinInstancesPerNode", min_instances_per_node) %>%
    invoke("setCacheNodeIds", cache_node_ids) %>%
    invoke("setMaxMemoryInMB", max_memory_in_mb) %>%
    invoke("setLossType", loss_type) %>%
    invoke("setMaxIter", max_iter) %>%
    invoke("setStepSize", step_size) %>%
    invoke("setSubsamplingRate", subsampling_rate)

  if (!rlang::is_null(seed))
    jobj <- invoke(jobj, "setSeed", seed)

  new_ml_gbt_regressor(jobj)
}

#' @export
ml_gbt_regressor.ml_pipeline <- function(
  x,
  formula = NULL,
  max_iter = 20L,
  max_depth = 5L,
  step_size = 0.1,
  subsampling_rate = 1,
  min_instances_per_node = 1L,
  max_bins = 32L,
  min_info_gain = 0,
  loss_type = "squared",
  seed = NULL,
  checkpoint_interval = 10L,
  cache_node_ids = FALSE,
  max_memory_in_mb = 256L,
  features_col = "features",
  label_col = "label",
  prediction_col = "prediction",
  uid = random_string("gbt_regressor_"), ...) {

  transformer <- ml_new_stage_modified_args()
  ml_add_stage(x, transformer)
}

#' @export
ml_gbt_regressor.tbl_spark <- function(
  x,
  formula = NULL,
  max_iter = 20L,
  max_depth = 5L,
  step_size = 0.1,
  subsampling_rate = 1,
  min_instances_per_node = 1L,
  max_bins = 32L,
  min_info_gain = 0,
  loss_type = "squared",
  seed = NULL,
  checkpoint_interval = 10L,
  cache_node_ids = FALSE,
  max_memory_in_mb = 256L,
  features_col = "features",
  label_col = "label",
  prediction_col = "prediction",
  uid = random_string("gbt_regressor_"),
  response = NULL,
  features = NULL, ...) {

  predictor <- ml_new_stage_modified_args()

  ml_formula_transformation()

  if (is.null(formula)) {
    predictor %>%
      ml_fit(x)
  } else {
    ml_generate_ml_model(
      x, predictor, formula, features_col, label_col,
      "regression", new_ml_model_gbt_regression
    )
  }
}

# Validator
ml_validator_gbt_regressor <- function(args, nms) {
  old_new_mapping <- c(
    ml_tree_param_mapping(),
    list(num.trees = "max_iter",
         loss.type = "loss_type",
         sample.rate = "subsampling_rate"
    )
  )

  args %>%
    ml_validate_decision_tree_args() %>%
    ml_validate_args({
      max_iter <- ensure_scalar_integer(max_iter)
      step_size <- ensure_scalar_double(step_size)
      subsampling_rate <- ensure_scalar_double(subsampling_rate)
      loss_type <- ensure_scalar_character(loss_type)
    }, old_new_mapping) %>%
    ml_extract_args(nms, old_new_mapping)
}

# Constructors

new_ml_gbt_regressor <- function(jobj) {
  new_ml_predictor(jobj, subclass = "ml_gbt_regressor")
}

new_ml_gbt_regression_model <- function(jobj) {

  new_ml_prediction_model(
    jobj,
    feature_importances = try_null(read_spark_vector(jobj, "featureImportances")),
    num_trees = invoke(jobj, "numTrees"),
    num_features = invoke(jobj, "numFeatures"),
    total_num_nodes = invoke(jobj, "totalNumNodes"),
    tree_weights = invoke(jobj, "treeWeights"),
    trees = invoke(jobj, "trees") %>%
      lapply(new_ml_decision_tree_regression_model),
    features_col = invoke(jobj, "getFeaturesCol"),
    prediction_col = invoke(jobj, "getPredictionCol"),
    subclass = "ml_gbt_regression_model")
}

new_ml_model_gbt_regression <- function(
  pipeline, pipeline_model, model, dataset, formula, feature_names, call) {

  new_ml_model_regression(
    pipeline, pipeline_model, model, dataset, formula,
    subclass = "ml_model_gbt_regression",
    .features = feature_names,
    .call = call
  )
}
