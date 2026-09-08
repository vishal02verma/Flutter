import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  Widget _featureItem(
      IconData icon,
      String title,
      Color iconColor,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 30,
          color: iconColor,
        ),

        const SizedBox(width: 5),

        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.brown.shade700,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 900;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'About Ayansh Bakery',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.brown.shade800,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/profile_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: isDesktop ? 3 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            const Text(
                              'Ayansh    🤎',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                                color: Colors.brown,
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, -18),
                              child: const Text(
                                '𝘉𝘢𝘬𝘦𝘳𝘺   ',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            Container(
                              height: 35,
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 300),
                              decoration: BoxDecoration(
                                color: Colors.brown.shade600,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  'Fresh . Delicious . Quality',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                'At Ayansh Bakery, we believe every celebration deserves something sweet and memorable. We bake happiness in every bite.',
                                style: TextStyle(
                                  color: Colors.brown.shade500,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isDesktop || size.width > 400)
                      Expanded(
                        flex: isDesktop ? 2 : 1,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            height: isDesktop ? 300 : 200,
                            decoration: BoxDecoration(
                              image: const DecorationImage(
                                image: AssetImage('assets/images/about img.png'),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(isDesktop ? 20 : 100),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildAboutSection(
                    context,
                    Icons.storefront_outlined,
                    "About Us",
                    "Ayansh Bakery is all about spreading happiness with our fresh, delicious and high-quality bakery products. Every item is made with love, care and the finest ingredients. We hope you enjoy our products to make every moment special.",
                  ),
                  const SizedBox(height: 12),
                  _buildAboutSection(
                    context,
                    Icons.track_changes_sharp,
                    "Our Mission",
                    "To provide fresh, delicious and high-quality bakery products with excellent customer service.",
                    titleColor: Colors.red.shade600,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 5)],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.workspace_premium,
                            color: Colors.brown.shade800,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Why Choose Us?",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.brown.shade600,
                                ),
                              ),
                              const SizedBox(height: 15),
                              GridView.count(
                                crossAxisCount: isDesktop ? 3 : 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: isDesktop ? 2.5 : 1.4,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                children: [
                                  _featureItem(Icons.energy_savings_leaf_outlined, "Fresh & Quality\nIngredients", Colors.green),
                                  _featureItem(Icons.verified_user_sharp, "Hygienic\nPreparation", Colors.yellow.shade900),
                                  _featureItem(Icons.local_restaurant_sharp, "Delicious Taste", Colors.brown),
                                  _featureItem(Icons.price_change_outlined, "Affordable Prices", Colors.yellow.shade900),
                                  _featureItem(Icons.cake_outlined, "Fresh Made Cakes", Colors.brown),
                                  _featureItem(Icons.label_important_outline, "Egg Free Cake", Colors.yellow.shade900),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, IconData icon, String title, String content, {Color? titleColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange.shade50.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.brown.shade800,
              size: 32,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: titleColor ?? Colors.brown.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.brown.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
