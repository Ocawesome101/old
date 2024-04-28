package net.mcreator.morpicks;

import net.minecraftforge.registries.ObjectHolder;

import net.minecraft.item.crafting.Ingredient;
import net.minecraft.item.SwordItem;
import net.minecraft.item.Items;
import net.minecraft.item.ItemStack;
import net.minecraft.item.ItemGroup;
import net.minecraft.item.Item;
import net.minecraft.item.IItemTier;

@Elementsmorpicks.ModElement.Tag
public class MCreatorEmeraldSword extends Elementsmorpicks.ModElement {
	@ObjectHolder("morpicks:emeraldsword")
	public static final Item block = null;

	public MCreatorEmeraldSword(Elementsmorpicks instance) {
		super(instance, 3);
	}

	@Override
	public void initElements() {
		elements.items.add(() -> new SwordItem(new IItemTier() {
			public int getMaxUses() {
				return 5000;
			}

			public float getEfficiency() {
				return 7f;
			}

			public float getAttackDamage() {
				return 10f;
			}

			public int getHarvestLevel() {
				return 4;
			}

			public int getEnchantability() {
				return 15;
			}

			public Ingredient getRepairMaterial() {
				return Ingredient.fromStacks(new ItemStack(Items.EMERALD, (int) (1)));
			}
		}, 3, -1.4F, new Item.Properties().group(ItemGroup.COMBAT)) {
		}.setRegistryName("emeraldsword"));
	}
}
