// Copyright Epic Games, Inc. All Rights Reserved.


#include "SurvivalStatsComponent.h"

USurvivalStatsComponent::USurvivalStatsComponent()
{
	PrimaryComponentTick.bCanEverTick = false;
}

void USurvivalStatsComponent::BeginPlay()
{
	Super::BeginPlay();

	Hydration = FMath::Min(Hydration, MaxHydration);
	Satiety = FMath::Min(Satiety, MaxSatiety);
	Warmth = FMath::Min(Warmth, MaxWarmth);
}

float USurvivalStatsComponent::CalculatePercentage(float Level, float MaxLevel)
{
	return MaxLevel > 0.0f ? Level / MaxLevel : 0.0f;
}

void USurvivalStatsComponent::ApplyLevel(ESurvivalStat Stat, float& Level, float MaxLevel, float NewLevel)
{
	const float ClampedLevel = FMath::Clamp(NewLevel, 0.0f, MaxLevel);

	if (ClampedLevel == Level)
	{
		return;
	}

	Level = ClampedLevel;

	OnSurvivalStatChanged.Broadcast(Stat, CalculatePercentage(Level, MaxLevel));
}

void USurvivalStatsComponent::ApplyMaxLevel(ESurvivalStat Stat, float& Level, float& MaxLevel, float NewMaxLevel)
{
	const float ClampedMaxLevel = FMath::Max(NewMaxLevel, 0.0f);

	if (ClampedMaxLevel == MaxLevel)
	{
		return;
	}

	MaxLevel = ClampedMaxLevel;

	if (Level > MaxLevel)
	{
		ApplyLevel(Stat, Level, MaxLevel, MaxLevel);
	}
	else
	{
		OnSurvivalStatChanged.Broadcast(Stat, CalculatePercentage(Level, MaxLevel));
	}
}

void USurvivalStatsComponent::SetHydration(float NewHydration)
{
	ApplyLevel(ESurvivalStat::Hydration, Hydration, MaxHydration, NewHydration);
}

void USurvivalStatsComponent::AddHydration(float Amount)
{
	SetHydration(Hydration + Amount);
}

void USurvivalStatsComponent::SetMaxHydration(float NewMaxHydration)
{
	ApplyMaxLevel(ESurvivalStat::Hydration, Hydration, MaxHydration, NewMaxHydration);
}

void USurvivalStatsComponent::SetSatiety(float NewSatiety)
{
	ApplyLevel(ESurvivalStat::Satiety, Satiety, MaxSatiety, NewSatiety);
}

void USurvivalStatsComponent::AddSatiety(float Amount)
{
	SetSatiety(Satiety + Amount);
}

void USurvivalStatsComponent::SetMaxSatiety(float NewMaxSatiety)
{
	ApplyMaxLevel(ESurvivalStat::Satiety, Satiety, MaxSatiety, NewMaxSatiety);
}

void USurvivalStatsComponent::SetWarmth(float NewWarmth)
{
	ApplyLevel(ESurvivalStat::Warmth, Warmth, MaxWarmth, NewWarmth);
}

void USurvivalStatsComponent::AddWarmth(float Amount)
{
	SetWarmth(Warmth + Amount);
}

void USurvivalStatsComponent::SetMaxWarmth(float NewMaxWarmth)
{
	ApplyMaxLevel(ESurvivalStat::Warmth, Warmth, MaxWarmth, NewMaxWarmth);
}
