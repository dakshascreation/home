-- Optional starter catalogue. Run after schema.sql.
-- Replace names, prices, quantities and photos with your real catalogue.
insert into public.products (name, category, description, price, quantity, image_url)
select s.name, s.category, s.description, s.price, s.quantity, null
from (values
 ('Golden Hour Necklace','Necklace','A warm golden everyday favourite.',1299,8),
 ('Everyday Gold Bracelet','Bracelet','A little sparkle for every day.',799,12),
 ('Petal Nosepin','Nosepin','A delicate finishing touch.',449,10),
 ('Heirloom Drop Earrings','Earrings','A timeless piece for your collection.',999,6),
 ('Moonlight Necklace','Necklace','A statement with a soft glow.',1599,5),
 ('Dainty Link Bracelet','Bracelet','Made for effortless layering.',649,9),
 ('Little Star Nosepin','Nosepin','Small detail, lovely impact.',399,7),
 ('Golden Bloom Earrings','Earrings','A floral-inspired favourite.',1099,4)
) as s(name,category,description,price,quantity)
where not exists (select 1 from public.products p where p.name = s.name);
