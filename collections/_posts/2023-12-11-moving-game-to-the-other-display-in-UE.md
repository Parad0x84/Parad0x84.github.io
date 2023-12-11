---
title: Moving Game To The Other Display In UE
date: 2023-12-11 12:53:54 +0300
categories: [Unreal Engine]
tags: [Unreal Engine, UE, UE5, Monitor, Display, CPP, C++]
---

> Hi reader, this is the first post of my website, so I would like to hear about any suggestions or feedbacks in the comments section. Thanks in advance :)
{: .prompt-info }

## Opening

Let's say you wanna create an option to allow players to change the display where game is rendering, how do you do that in Unreal Engine?

![Example Of The Display Setting](/assets/img/post/2023-12-11-moving-game-to-the-other-display-in-UE/Example_Display_Option.png){: width="972" height="589" }
_Example Of The Display Setting_

I was wondering the same thing a few days ago, so I decided to tinker around and implement this feature. I thought it will be easy, but... Let's get to it.

## First Try
If you ever created an options menu of some kind, you probably know first place to look at is `UGameUserSettings`.
For those who doesn't know about it, it's a good high level interface to change some graphical settings without getting too deep into engine. Also it's exposed to the Blueprints

![Example Image Of The Setting](/assets/img/post/2023-12-11-moving-game-to-the-other-display-in-UE/Example_Game_User_Settings.png){: width="972" height="589" }
_Example Of The GameUserSettings_

But unfortunately, the function I'm looking for isn't exposed to the `UGameUserSettings`, so we need to go a bit deeper.

<br />

## The Solution

I have to admit, it was a loot deeper than I thought but here is the solution I found:

First of all we need a way to retrieve a list of displays that is connected to players PC.

```cpp
FDisplayMetrics Metrics;
FDisplayMetrics::RebuildDisplayMetrics(Metrics);
```

<br />

`FDisplayMetrics` contains following members:
```cpp
int32 PrimaryDisplayWidth;
int32 PrimaryDisplayHeight;
TArray<FMonitorInfo> MonitorInfo;
FPlatformRect PrimaryDisplayWorkAreaRect;
FPlatformRect VirtualDisplayRect;
FVector4 TitleSafePaddingSize;
FVector4 ActionSafePaddingSize;
```

we are only interested in `MonitorInfo` for the purposes of this article, but feel free to play around. It is a list of all the displays.

`FMonitorInfo` contains following members:
```cpp
FString Name;
FString ID;
int32 NativeWidth = 0;
int32 NativeHeight = 0;
FIntPoint MaxResolution = FIntPoint(ForceInitToZero);
FPlatformRect DisplayRect;
FPlatformRect WorkArea;
bool bIsPrimary = false;
int32 DPI = 0;
```
> If you wanna check the resolution of the displays use `NativeWidth` and `NativeHeight`. For some reason `MaxResolution` didn't work for me. Keep in mind it might be a bug on my end or an issue with the engine
{: .prompt-warning }

I'm not gonna dive into it any further, but for creating this kind of an option UI, you have everything in these structs. For the sake of simplicity I'll assume you already know which display you wanna change to.

So let's say you have an ID for the display you wanna use and it's stored into a variable named `TargetDisplayID`

```cpp
FDisplayMetrics Metrics;
FDisplayMetrics::RebuildDisplayMetrics(Metrics);

// Get the index of target display 
int TargetDisplayIndex = -1;
for(int i = 0; i < Metrics.MonitorInfo.Num(); i++)
{
    if(Metrics.MonitorInfo[i].ID == TargetDisplayID)
    {
        TargetDisplayIndex = i;
        break;
    }
}

if(TargetDisplayIndex == -1)
{
    // We couldn't find requested display
    // Throw an error, log failure, etc
}

// Get the position of requested display in the virtual space of all the displays combined
// For example if 2x 1080p displays is positioned side by side, top left corner of the right display would be (1920, 0) instead of (0, 0)
const FMonitorInfo& TargetDisplay = Metrics.MonitorInfo[TargetDisplayIndex];
const FVector2D WindowPosition = FVector2D(TargetDisplay.DisplayRect.Left, TargetDisplay.DisplayRect.Top);

if(GEngine && GEngine->GameViewport)
{
    // Here we are getting native window. A lot deeper than I intended...
    TSharedPtr<FGenericWindow> nativeWindow = GEngine->GameViewport->GetWindow()->GetNativeWindow();

    // Basically we are getting into windowed mode and moving window to the target display
    // Then we are going back into fullscreen or windowed fullscreen
    // Not clean, not the best way, but it's the only way works (which I can find)
    nativeWindow->SetWindowMode(EWindowMode::Windowed);
    nativeWindow->MoveWindowTo(WindowPosition.X, WindowPosition.Y);
    nativeWindow->SetWindowMode(EWindowMode::WindowedFullscreen);
}
```

Ideally you could just handle it from `UGameViewportClient` and it would be exposed to the Blueprints too, but here we are.

Hope this article helps, see you in the comments section!
