# HousePricePredictorExtended Metrics

Author: Stepan Karabelnikov

Dataset: `house_prices.csv`

Target: `price`

Features: `area`, `total_rooms`, `bathrooms`, `garage_spaces`, `distance_to_center`, `floor`, `build_year`, `balcony`, `renovation_level`, `has_elevator`, `ceiling_height`, `district_rating`

Validation setup: automatic 30% validation split in Create ML.

Recorded metrics:

| Metric | Value |
| --- | ---: |
| RMSE | 1 350 000 ₽ |
| MAE | 980 000 ₽ |
| Mean price | 21 850 000 ₽ |
| RMSE / mean price | 6.2% |
| MAE / mean price | 4.5% |

These metrics satisfy the lab threshold of RMSE below 20% of average price.
