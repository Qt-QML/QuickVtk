---
layout: subpage
nav: docs
title: Part 4 - Properties
category: Implementing a VTK wrapper in QuickVtk
---

## Identifying Properties
We are able to instantiate our custom `PointSource` type from [QML](https://doc.qt.io/qt-5/qtqml-index.html) and have access to the underlying [vtkPointSource](https://vtk.org/doc/nightly/html/classvtkPointSource.html) object. Now we can start adding some properties to our wrapper which we can then access from [QML](https://doc.qt.io/qt-5/qtqml-index.html).

Based on the [vtkPointSource documentation](https://vtk.org/doc/nightly/html/classvtkPointSource.html) we will first have to identify all available class attributes


VTK attribute | VTK type
:--- | :---
NumberOfPoints | vtkIdType
Center | double [3]
Radius | double
Distribution | int
OutputPointsPrecision | int
RandomSequence | vtkRandomSequence

## Adding a Q_PROPERTY
Let's start with `NumberOfPoints` which controls how many individual points are generated by [vtkPointSource](https://vtk.org/doc/nightly/html/classvtkPointSource.html). In order to create a property for this class attribute, we have to know which [QML](https://doc.qt.io/qt-5/qtqml-index.html) type to use for `vtkIdType`. This type is defined in [vtkType.h](https://vtk.org/doc/nightly/html/vtkType_8h_source.html) and is simply a typedef for `long long`, `long` or `int` depending on the [VTK](https://vtk.org/) build configuration. The important part is that `NumberOfPoints` is an integer number. We don't really care about different precisions since [QML](https://doc.qt.io/qt-5/qtqml-index.html) uses the built-in `int` type for any integer number. You can read more about C++/[QML](https://doc.qt.io/qt-5/qtqml-index.html) type conversion in [this article](https://doc.qt.io/qt-5/qtqml-cppintegration-data.html) from the Qt docs. The [type conversion reference]({{ site.baseurl }}/reference/type-conversion) provides an overview for basic [VTK](https://vtk.org/)/[QML](https://doc.qt.io/qt-5/qtqml-index.html) type conversion.

We can use the `Q_PROPERTY` macro to define a new `numberOfPoints` property together with the associated `get-`, `set-`, and `-changed` method declarations. Note that QuickVtk uses **camelCase** for all property names since this is the standard for properties in [QML](https://doc.qt.io/qt-5/qtqml-index.html).

>quickVtkPointSource.hpp
{: .hl-caption}

{% highlight cpp %}
#pragma once

#include "quickVtkPolyDataAlgorithm.hpp"
#include <vtkPointSource.h>

namespace quick {
  namespace Vtk {

    class PointSource : public PolyDataAlgorithm {
      Q_OBJECT
      Q_PROPERTY(int numberOfPoints READ getNumberOfPoints WRITE setNumberOfPoints NOTIFY numberOfPointsChanged);
    private:
      static Qml::Register::Class<PointSource> Register;
      vtkSmartPointer<vtkPointSource> m_vtkObject;
    public:
      PointSource();
      auto setNumberOfPoints(int) -> void;
      auto getNumberOfPoints() -> int;
    signals:
      void numberOfPointsChanged();
    };
  }
}
{% endhighlight %}

As you can see, `Q_PROPERTY` uses the `READ`, `WRITE`, and `NOTIFY` macros which link the property to `get-`, `set-` and `-notify` methods. While QuickVtk uses trailing return types for all methods by default, signals only support the classic return type notation.

Let's take a look at the implementation of our property accessors next.

>quickVtkPointSource.cpp
{: .hl-caption}

{% highlight cpp %}
#include "quickVtkPointSource.hpp"

namespace quick {
  namespace Vtk {

    Qml::Register::Class<PointSource> PointSource::Register(true);

    PointSource::PointSource() : PolyDataAlgorithm(vtkSmartPointer<vtkPointSource>::New()) {
      this->m_vtkObject = vtkPointSource::SafeDownCast(Algorithm::getVtkObject());
    }

    auto PointSource::setNumberOfPoints(int numberOfPoints) -> void {
      this->m_vtkObject->SetNumberOfPoints(numberOfPoints);
      emit this->numberOfPointsChanged();
      this->update();
    }

    auto PointSource::getNumberOfPoints() -> int {
      return this->m_vtkObject->GetNumberOfPoints();
    }
  }
}

{% endhighlight %}

The [property system](https://doc.qt.io/qt-5/properties.html) uses `get-` and `set-` methods to read/write values from/to our C++ instance. These methods are basically callbacks which will be executed every time a property is accessed from [QML](https://doc.qt.io/qt-5/qtqml-index.html).

New values will be forwarded to the underlying [vtkPointSource](https://vtk.org/doc/nightly/html/classvtkPointSource.html) object using the private `m_vtkObject` member. We also have to inform the [QML](https://doc.qt.io/qt-5/qtqml-index.html) engine if the property value was changed by emitting a `-notified` signal and update the visualization pipeline in order to render a new frame. We will to this by using the `update` method which is available for all [Vtk::Algorithm]({{ site.baseurl }}/api/Vtk/Algorithm)-derived classes.

### getNumberOfPoints
This method will be called from [QML](https://doc.qt.io/qt-5/qtqml-index.html) to retrieve the value for the `numberOfPoints` property. We will return the value directly from `m_vtkObject->GetNumberOfPoints()` to make sure that our wrapper always returns the same value that our [vtkPointSource](https://vtk.org/doc/nightly/html/classvtkPointSource.html) object is operating on.

### setNumberOfPoints
This method will be called from [QML](https://doc.qt.io/qt-5/qtqml-index.html) every time a new value is assigned to the `numberOfPoints` property. There are three steps involved in applying a new value to this property:

- `m_vtkObject->SetNumberOfPoints(numberOfPoints)` forwards the value to the [vtkPointSource](https://vtk.org/doc/nightly/html/classvtkPointSource.html) object
- `emit numberOfPointsChanged()` tells [QML](https://doc.qt.io/qt-5/qtqml-index.html) that all observers of the `numberOfPoints` property should be updated. We will take a closer look at `-changed` signals a bit later
- `update()` is an inherited method from the [Vtk::Algorithm]({{ site.baseurl }}/api/Vtk/Algorithm) base class. Basically, all algorithms in the context of [VTK](https://vtk.org/) are connectable nodes in the visualization pipeline. If a single node changes, the whole pipeline has to be updated in order to create an updated frame which we then are going to render using a [Vtk::Viewer]({{ site.baseurl }}/api/Vtk/Viewer) object

### The onNumberOfPointsChanged signal
While `getNumberOfPoints` and `setNumberOfPoints` are both implemented in the **.cpp** file, the `numberOfPointsChanged` method is only declared as a signal in the header file. The [Meta-Object Compiler (moc)](https://doc.qt.io/qt-5/moc.html) does the work for us and we only have to `emit` this signal after a value was changed. First, we want to test if we can access the `numberOfPoints` property in [QML](https://doc.qt.io/qt-5/qtqml-index.html). But after that we will take a look at why it is important to `emit` this signal and what happens if we don't.

## Property Access in QML
After rebuilding the project we should have access to the `numberOfPoints` property. In order to render the [VTK](https://vtk.org/) content in [QML](https://doc.qt.io/qt-5/qtqml-index.html), we will implement a simple visualization pipeline and use a [Vtk::Viewer]({{ site.baseurl }}/api/Vtk/Viewer) component

>PointSource.qml
{: .hl-caption}

{% highlight qml %}
import Vtk 1.0 as Vtk

Vtk.Viewer {
  anchors.fill: parent;

  mouseEnabled: true;

  Vtk.Actor {
    Vtk.PolyDataMapper {
      Vtk.PointSource {
        numberOfPoints: 20000;
      }
    }
  }
}

{% endhighlight %}

Instead of using a constant value of `20000`, we can bind the `numberOfPoints` property to a control element so that our example becomes a bit more interactive. QuickVtk provides some user input components in the `Utils` module. We will import this module and use a `Slider` element to adjust the `numberOfPoints` property.

>PointSource.qml
{: .hl-caption}

{% highlight qml %}
import QtQuick 2.9
import Vtk 1.0 as Vtk
import Utils 1.0 as Utils

Item {
  anchors.fill: parent

  Vtk.Viewer {
    anchors.fill: parent

    mouseEnabled: true;

    Vtk.Actor {
      Vtk.PolyDataMapper {
        Vtk.PointSource {
          id: source
          numberOfPoints: 20000
        }
      }
    }
  }

  Utils.View {
    Utils.Slider {
      from: source
      bind: "numberOfPoints"

      min: 1000
      max: 50000
      step: 100
      value: 1000
    }
  }
}

{% endhighlight %}

Note that the root object is a simple [QML Item](https://doc.qt.io/qt-5/qml-qtquick-item.html). This is necessary because the `Vtk.Viewer` type expects all child-components to be subclasses of [Vtk.Object]({{ site.baseurl }}/api/Vtk/Object). Since regular types from [QML](https://doc.qt.io/qt-5/qtqml-index.html) can not be used within the [VTK](https://vtk.org/) visualization pipeline, we simply moved the [Vtk::Viewer]({{ site.baseurl }}/api/Vtk/Viewer) component down in the object hierarchy. This way we can use types from [VTK](https://vtk.org/) and [QML](https://doc.qt.io/qt-5/qtqml-index.html) side by side.

We will discuss the `Utils` module in more detail later. But just by looking at the code we can figure things out. First, we specify that we **bind** a certain property **from** a certain object to the `Slider`. Interacting with the `Slider` changes the `numberOfPoints` property. This means that the `setNumberOfPoints` accessor was called from where the value is forwarded to the [vtkPointSource](https://vtk.org/doc/nightly/html/classvtkPointSource.html). We can see that the changing values for the `numberOfPoints` property are immediately visualizied.

## More About Signals
As stated earlier, the `-changed` signal of a property tells all observers that the property value changed. In order to demonstrate what this means, we will reuse the code from the above **.qml** snippet. We will add a [Text](https://doc.qt.io/qt-5/qml-qtquick-text.html) component and bind it to the `numberOfPoints` property.

>PointSource.qml
{: .hl-caption}

{% highlight qml %}
import QtQuick 2.9
import Vtk 1.0 as Vtk
import Utils 1.0 as Utils

Item {
  anchors.fill: parent

  Vtk.Viewer {
    anchors.fill: parent

    mouseEnabled: true;

    Vtk.Actor {
      Vtk.PolyDataMapper {
        Vtk.PointSource {
          id: source
          numberOfPoints: 20000
        }
      }
    }
  }

  Utils.View {
    Utils.Slider {
      from: source
      bind: "numberOfPoints"

      min: 1000
      max: 50000
      step: 100
      value: 1000
    }
  }

  Text {
    color: "#fff";
    text: "number of points: " + source.numberOfPoints;
  }
}

{% endhighlight %}

We bind the [Text](https://doc.qt.io/qt-5/qml-qtquick-text.html) component's `text` property to the `numberOfPoints` property by referencing `source.numberOfPoints` in the assignment. Every time the `numberOfPoints` property changes, the text will be updated. This only works because we are emitting the changed-signal in the `setNumberOfPoints` accessor. Emitting this signal tells all observers that they need to re-evaluate their value based on the observed property.

If you delete or comment the `emit this->numberOfPointsChanged()` statement in the `setNumberOfPoints` method, the [Text](https://doc.qt.io/qt-5/qml-qtquick-text.html) component will no longer react to value changes after interacting with the slider.

You might wonder why observers are not re-evaluated automatically after assigning a value to the observed property. By emitting signals from C++ explicitly, we have more control over our properties in terms of performance. We could cache previously assigned values and compare them to new property values like shown in the following example:

>Optimizing Property Assignments
{: .hl-caption}

{% highlight cpp %}

auto PointSource::setNumberOfPoints(int numberOfPoints) -> void {
  if (this->m_numberOfPoints != numberOfPoints) {
    this->m_numberOfPoints = numberOfPoints;
    this->m_vtkObject->SetNumberOfPoints(numberOfPoints);
    emit this->numberOfPointsChanged();
    this->update();  
  }
}

{% endhighlight %}

We would simply do nothing if the same value was assigned multiple times. We could avoid redundant updates of the visualization pipeline and also bypass emitting the `-changed` signal which can take some pressure off the [QML](https://doc.qt.io/qt-5/qtqml-index.html) engine. While implementing this for all properties is generally a good idea, you will find this only occasionally in QuickVtk. Mainly because the little performance gain in some very rare edge cases is not worth adding the relative amount of code complexity.