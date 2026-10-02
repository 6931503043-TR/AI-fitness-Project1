import cv2
import mediapipe as mp

mp_pose = mp.solutions.pose
mp_draw = mp.solutions.drawing_utils

cap = cv2.VideoCapture(0)  # ถ้าจอดำ ลองเปลี่ยนเป็น 1

with mp_pose.Pose(min_detection_confidence=0.5,
                  min_tracking_confidence=0.5) as pose:
    while cap.isOpened():
        ok, frame = cap.read()
        if not ok:
            break

        frame = cv2.flip(frame, 1)
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        result = pose.process(rgb)

        if result.pose_landmarks:
            mp_draw.draw_landmarks(frame, result.pose_landmarks,
                                   mp_pose.POSE_CONNECTIONS)

        cv2.imshow("Body Tracking", frame)
        if cv2.waitKey(1) & 0xFF == 27:  # กด ESC เพื่อออก
            break

cap.release()
cv2.destroyAllWindows()