// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "SurvivalStatsComponent.generated.h"

UENUM(BlueprintType)
enum class ESurvivalStat : uint8
{
	Hydration,
	Satiety,
	Warmth
};

DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FSurvivalStatChangedDelegate, ESurvivalStat, Stat, float, Percentage);

UCLASS(Blueprintable, ClassGroup="Survival", meta = (BlueprintSpawnableComponent))
class LABAPROJECT_API USurvivalStatsComponent : public UActorComponent
{
	GENERATED_BODY()

protected:

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Survival", meta = (ClampMin = 0))
	float MaxHydration = 100.0f;
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Survival", meta = (ClampMin = 0))
	float Hydration = 100.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Survival", meta = (ClampMin = 0))
	float MaxSatiety = 100.0f;
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Survival", meta = (ClampMin = 0))
	float Satiety = 100.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Survival", meta = (ClampMin = 0))
	float MaxWarmth = 100.0f;
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Survival", meta = (ClampMin = 0))
	float Warmth = 50.0f;

	virtual void BeginPlay() override;

	static float CalculatePercentage(float Level, float MaxLevel);

	void ApplyLevel(ESurvivalStat Stat, float& Level, float MaxLevel, float NewLevel);

	void ApplyMaxLevel(ESurvivalStat Stat, float& Level, float& MaxLevel, float NewMaxLevel);

public:

	UPROPERTY(BlueprintAssignable, Category="Survival")
	FSurvivalStatChangedDelegate OnSurvivalStatChanged;

	USurvivalStatsComponent();

	UFUNCTION(BlueprintPure, Category="Survival|Hydration")
	float GetHydration() const { return Hydration; }

	UFUNCTION(BlueprintCallable, Category="Survival|Hydration")
	void SetHydration(float NewHydration);

	UFUNCTION(BlueprintCallable, Category="Survival|Hydration")
	void AddHydration(float Amount);

	UFUNCTION(BlueprintPure, Category="Survival|Hydration")
	float GetMaxHydration() const { return MaxHydration; }

	UFUNCTION(BlueprintPure, Category="Survival|Hydration")
	float GetHydrationPercentage() const { return CalculatePercentage(Hydration, MaxHydration); }

	UFUNCTION(BlueprintCallable, Category="Survival|Hydration")
	void SetMaxHydration(float NewMaxHydration);

	UFUNCTION(BlueprintPure, Category="Survival|Satiety")
	float GetSatiety() const { return Satiety; }

	UFUNCTION(BlueprintCallable, Category="Survival|Satiety")
	void SetSatiety(float NewSatiety);

	UFUNCTION(BlueprintCallable, Category="Survival|Satiety")
	void AddSatiety(float Amount);

	UFUNCTION(BlueprintPure, Category="Survival|Satiety")
	float GetMaxSatiety() const { return MaxSatiety; }

	UFUNCTION(BlueprintPure, Category="Survival|Satiety")
	float GetSatietyPercentage() const { return CalculatePercentage(Satiety, MaxSatiety); }

	UFUNCTION(BlueprintCallable, Category="Survival|Satiety")
	void SetMaxSatiety(float NewMaxSatiety);

	UFUNCTION(BlueprintPure, Category="Survival|Warmth")
	float GetWarmth() const { return Warmth; }

	UFUNCTION(BlueprintCallable, Category="Survival|Warmth")
	void SetWarmth(float NewWarmth);

	UFUNCTION(BlueprintCallable, Category="Survival|Warmth")
	void AddWarmth(float Amount);

	UFUNCTION(BlueprintPure, Category="Survival|Warmth")
	float GetMaxWarmth() const { return MaxWarmth; }

	UFUNCTION(BlueprintPure, Category="Survival|Warmth")
	float GetWarmthPercentage() const { return CalculatePercentage(Warmth, MaxWarmth); }

	UFUNCTION(BlueprintCallable, Category="Survival|Warmth")
	void SetMaxWarmth(float NewMaxWarmth);
};
