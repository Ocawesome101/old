package net.mcreator.lightsabers;

import net.minecraftforge.registries.ObjectHolder;

import net.minecraft.item.crafting.Ingredient;
import net.minecraft.item.SwordItem;
import net.minecraft.item.Items;
import net.minecraft.item.ItemStack;
import net.minecraft.item.Item;
import net.minecraft.item.IItemTier;

@Elementslightsabers.ModElement.Tag
public class MCreatorGreenLightsaber extends Elementslightsabers.ModElement {
	@ObjectHolder("lightsabers:greenlightsaber")
	public static final Item block = null;

	public MCreatorGreenLightsaber(Elementslightsabers instance) {
		super(instance, 1);
	}

	@Override
	public void initElements() {
		elements.items.add(() -> new SwordItem(new IItemTier() {
			public int getMaxUses() {
				return 0;
			}

			public float getEfficiency() {
				return 4f;
			}

			public float getAttackDamage() {
				return 17.5f;
			}

			public int getHarvestLevel() {
				return 1;
			}

			public int getEnchantability() {
				return 0;
			}

			public Ingredient getRepairMaterial() {
				return Ingredient.fromStacks(new ItemStack(Items.IRON_INGOT, (int) (1)));
			}
		}, 3, 6F, new Item.Properties().group(MCreatorLightsabersTab.tab)) {
		}.setRegistryName("greenlightsaber"));
	}
}
