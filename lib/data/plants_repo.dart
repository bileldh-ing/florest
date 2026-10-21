import 'plant.dart';

/// 16 plants: 8 outdoor, 4 indoor, 4 that live anywhere ("both").
/// Tab counts are computed from this list, never hardcoded.
abstract final class PlantsRepo {
  static const List<Plant> all = [
    Plant(
      id: 'aloe_vera',
      name: 'Aloe Vera',
      type: PlantType.outdoor,
      priceCents: 1800,
      asset: 'assets/plants/aloe_vera.webp',
      description:
          'A sun-loving succulent with thick, gel-filled leaves. Water deeply, then let the soil dry out completely before the next drink.',
      water: 'Every 3 weeks',
      temperature: '13–27 °C',
      light: 'Full sun',
    ),
    Plant(
      id: 'pontiatus_evo',
      name: 'Pontiatus Evo',
      type: PlantType.indoor,
      priceCents: 2400,
      asset: 'assets/plants/pontiatus_evo.webp',
      description:
          'Soft, rounded leaves that open like a green rose. Happy on a bright windowsill and forgiving if you forget a watering.',
      water: 'Weekly',
      temperature: '18–26 °C',
      light: 'Bright, indirect',
    ),
    Plant(
      id: 'boxwood_ball',
      name: 'Boxwood Ball',
      type: PlantType.outdoor,
      priceCents: 5600,
      asset: 'assets/plants/boxwood_ball.webp',
      description:
          'A dense evergreen sphere that keeps its shape all year. Trim lightly in late spring and keep the roots evenly moist.',
      water: '2× a week',
      temperature: '-10–30 °C',
      light: 'Sun to part shade',
    ),
    Plant(
      id: 'tillandsia_rosette',
      name: 'Tillandsia Rosette',
      type: PlantType.indoor,
      priceCents: 1400,
      asset: 'assets/plants/tillandsia_rosette.webp',
      description:
          'Succulents from the Tillandsia family are some of the easiest to care for - outside of an occasional misting.',
      water: 'Mist 2× a week',
      temperature: '15–30 °C',
      light: 'Bright, filtered',
    ),
    Plant(
      id: 'dracaena_burst',
      name: 'Dracaena Burst',
      type: PlantType.indoor,
      priceCents: 3800,
      asset: 'assets/plants/dracaena_burst.webp',
      description:
          'Spiky, lime-green leaves that radiate from a single crown. Tolerates lower light and dry office air with ease.',
      water: 'Every 10 days',
      temperature: '16–24 °C',
      light: 'Medium',
    ),
    Plant(
      id: 'echeveria_jade',
      name: 'Echeveria Jade',
      type: PlantType.outdoor,
      priceCents: 1600,
      asset: 'assets/plants/echeveria_jade.webp',
      description:
          'A perfect rosette of powdery, jade-tinted leaves. Give it gritty soil and plenty of sun for the tightest shape.',
      water: 'Every 2 weeks',
      temperature: '10–29 °C',
      light: 'Full sun',
    ),
    Plant(
      id: 'agave_blue',
      name: 'Blue Agave',
      type: PlantType.outdoor,
      priceCents: 4200,
      asset: 'assets/plants/agave_blue.webp',
      description:
          'Architectural, blue-grey blades with a sculptural silhouette. Thrives on neglect, hot afternoons and very little water.',
      water: 'Monthly',
      temperature: '5–35 °C',
      light: 'Full sun',
    ),
    Plant(
      id: 'lavender_dome',
      name: 'Lavender Dome',
      type: PlantType.outdoor,
      priceCents: 2200,
      asset: 'assets/plants/lavender_dome.webp',
      description:
          'A fragrant silver mound that bursts into purple spikes in summer. Loves lean soil, wind and long sunny days.',
      water: 'Weekly',
      temperature: '0–32 °C',
      light: 'Full sun',
    ),
    Plant(
      id: 'rosemary_mound',
      name: 'Rosemary Mound',
      type: PlantType.outdoor,
      priceCents: 1900,
      asset: 'assets/plants/rosemary_mound.webp',
      description:
          'Needle-like aromatic leaves on a compact, rounded shrub. Snip often for the kitchen and it grows back even fuller.',
      water: 'Weekly',
      temperature: '2–30 °C',
      light: 'Full sun',
    ),
    Plant(
      id: 'juniper_cushion',
      name: 'Juniper Cushion',
      type: PlantType.outdoor,
      priceCents: 4800,
      asset: 'assets/plants/juniper_cushion.webp',
      description:
          'A low, cushion-forming conifer with fine blue-green foliage. Hardy, drought tolerant and lovely in a wide bowl.',
      water: 'Every 10 days',
      temperature: '-15–30 °C',
      light: 'Full sun',
    ),
    Plant(
      id: 'sedum_carpet',
      name: 'Sedum Carpet',
      type: PlantType.outdoor,
      priceCents: 1500,
      asset: 'assets/plants/sedum_carpet.webp',
      description:
          'Tiny fleshy leaves knit together into a living carpet. Perfect for rooftops, rock gardens and shallow planters.',
      water: 'Every 2 weeks',
      temperature: '-5–30 °C',
      light: 'Sun',
    ),
    Plant(
      id: 'calathea_orbifolia',
      name: 'Calathea Orbifolia',
      type: PlantType.indoor,
      priceCents: 4400,
      asset: 'assets/plants/calathea_orbifolia.webp',
      description:
          'Huge round leaves striped in silver that fold up at night. Likes humidity, soft water and a spot out of direct sun.',
      water: '2× a week',
      temperature: '18–27 °C',
      light: 'Low to medium',
    ),
    Plant(
      id: 'haworthia_zebra',
      name: 'Haworthia Zebra',
      type: PlantType.both,
      priceCents: 1200,
      asset: 'assets/plants/haworthia_zebra.webp',
      description:
          'Striped, pointed leaves in a tidy star. Small enough for a desk, tough enough for a sheltered balcony.',
      water: 'Every 2 weeks',
      temperature: '10–30 °C',
      light: 'Bright, indirect',
    ),
    Plant(
      id: 'fern_nest',
      name: "Bird's Nest Fern",
      type: PlantType.both,
      priceCents: 3200,
      asset: 'assets/plants/fern_nest.webp',
      description:
          'Glossy, wavy fronds unfurl from a central nest. Keep it moist and shaded, inside or on a covered patio.',
      water: '2× a week',
      temperature: '16–27 °C',
      light: 'Shade',
    ),
    Plant(
      id: 'peperomia_round',
      name: 'Peperomia Round',
      type: PlantType.both,
      priceCents: 2000,
      asset: 'assets/plants/peperomia_round.webp',
      description:
          'Coin-shaped leaves on a neat, bushy plant. Water when the top of the soil is dry and it will reward you all year.',
      water: 'Every 10 days',
      temperature: '15–26 °C',
      light: 'Medium',
    ),
    Plant(
      id: 'jade_crassula',
      name: 'Jade Crassula',
      type: PlantType.both,
      priceCents: 2600,
      asset: 'assets/plants/jade_crassula.webp',
      description:
          'Thick, glossy oval leaves on woody stems. A slow, long-lived classic that loves sun and hates wet feet.',
      water: 'Every 3 weeks',
      temperature: '10–30 °C',
      light: 'Full sun',
    ),
  ];
}
