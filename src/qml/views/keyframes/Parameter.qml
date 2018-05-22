/*
 * Copyright (c) 2018 Meltytech, LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtQml.Models 2.1
import org.shotcut.qml 1.0

Item {
    id: parameterRoot
    property alias model: keyframeDelegateModel.model
    property alias rootIndex: keyframeDelegateModel.rootIndex
    property bool isLocked: false

    signal clicked(var keyframe, var parameter)

    function getKeyframeCount() {
        return keyframesRepeater.count
    }

    function getKeyframe(keyframeIndex) {
        if (keyframeIndex < keyframesRepeater.count)
            return keyframesRepeater.itemAt(keyframeIndex)
        else
            return null
    }

    Repeater { id: keyframesRepeater; model: keyframeDelegateModel; onCountChanged: canvas.requestPaint() }

    Canvas {
        id: canvas
        visible: metadata !== null && metadata.keyframes.parameters[parameterRoot.DelegateModel.itemsIndex].isCurve
        anchors.fill: parent

        function catmullRomToBezier(context, i) {
            var a = 1.0 / 6.0
            var g = i-2 >= 0 ? i-2 : i
            var h = i-1 >= 0 ? i-1 : i
            var j = i+1 < keyframesRepeater.count ? i+1 : i
            var widthOffset = keyframesRepeater.itemAt(0).width / 2
            var heightOffset = keyframesRepeater.itemAt(0).height / 2
            var points = [
                {x: keyframesRepeater.itemAt(g).x + widthOffset, y: keyframesRepeater.itemAt(g).y + heightOffset},
                {x: keyframesRepeater.itemAt(h).x + widthOffset, y: keyframesRepeater.itemAt(h).y + heightOffset},
                {x: keyframesRepeater.itemAt(i).x + widthOffset, y: keyframesRepeater.itemAt(i).y + heightOffset},
                {x: keyframesRepeater.itemAt(j).x + widthOffset, y: keyframesRepeater.itemAt(j).y + heightOffset},
            ]
            context.bezierCurveTo(-a*points[0].x + points[1].x + a*points[2].x,
                                  -a*points[0].y + points[1].y + a*points[2].y,
                                   a*points[1].x + points[2].x - a*points[3].x,
                                   a*points[1].y + points[2].y - a*points[3].y,
                                     points[2].x, points[2].y)
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.strokeStyle = activePalette.buttonText
            ctx.lineWidth = 1.0
            ctx.clearRect(0, 0, canvas.width, canvas.height)
            ctx.beginPath()
            if (keyframesRepeater.count) {
                var widthOffset = keyframesRepeater.itemAt(0).width / 2
                var heightOffset = keyframesRepeater.itemAt(0).height / 2
                // Draw extent before first keyframe.
                var startX = (filter.in - producer.in) * timeScale
                ctx.moveTo(startX, keyframesRepeater.itemAt(0).y + heightOffset)
                ctx.lineTo(keyframesRepeater.itemAt(0).x + widthOffset, keyframesRepeater.itemAt(0).y + heightOffset)
                // Draw lines between keyframes.
                for (var i = 1; i < keyframesRepeater.count; i++) {
                    switch (keyframesRepeater.itemAt(i - 1).interpolation) {
                    case KeyframesModel.LinearInterpolation:
                        ctx.lineTo(keyframesRepeater.itemAt(i).x + widthOffset, keyframesRepeater.itemAt(i).y + heightOffset)
                        break
                    case KeyframesModel.SmoothInterpolation:
                        catmullRomToBezier(ctx, i)
                        ctx.moveTo(keyframesRepeater.itemAt(i).x + widthOffset, keyframesRepeater.itemAt(i).y + heightOffset)
                        break
                    default: // KeyframesModel.DiscreteInterpolation
                        ctx.lineTo(keyframesRepeater.itemAt(i).x + widthOffset, keyframesRepeater.itemAt(i - 1).y + heightOffset)
                        ctx.moveTo(keyframesRepeater.itemAt(i).x + widthOffset, keyframesRepeater.itemAt(i).y + heightOffset)
                        break
                    }
                }
                // Draw extent after last keyframe.
                ctx.lineTo((filter.out - producer.in + 1) * timeScale, keyframesRepeater.itemAt(i - 1).y + heightOffset)
            }
            ctx.stroke()
        }
    }

    DelegateModel {
        id: keyframeDelegateModel
        Keyframe {
            position: (filter.in - producer.in) + model.frame
            interpolation: model.interpolation
            name: model.name
            value: model.value
            isSelected: root.currentTrack === parameterRoot.DelegateModel.itemsIndex && root.selection.indexOf(index) !== -1
            parameterIndex: parameterRoot.DelegateModel.itemsIndex
            onClicked: parameterRoot.clicked(keyframe, parameterRoot)
            onInterpolationChanged: canvas.requestPaint()
            onPositionChanged: canvas.requestPaint()
            onValueChanged: canvas.requestPaint()
        }
    }
}
