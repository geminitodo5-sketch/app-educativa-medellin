// ─────────────────────────────────────────────────────────────
//  lib/data/services/firestore_sync_service.dart
//  Capa: Datos — Responsabilidad: Ingeniería
//
//  Sube y descarga progreso del estudiante hacia/desde Firestore.
//  No guarda estado local — solo opera sobre la nube.
//
//  Estructura Firestore:
//    /usuarios/{firebase_uid}
//      nombre, grado, personaje, email, edad, genero, fecha_registro
//
//    /usuarios/{firebase_uid}/progreso/{grado}_{materia}_{actividad}
//      grado, materia, actividad, porcentaje, intentos, ultima_vez
//
//  Reglas de Firestore recomendadas (Firebase Console → Firestore → Rules):
//    rules_version = '2';
//    service cloud.firestore {
//      match /databases/{database}/documents {
//        match /usuarios/{userId} {
//          allow read, write: if request.auth != null
//                             && request.auth.uid == userId;
//          match /progreso/{docId} {
//            allow read, write: if request.auth != null
//                               && request.auth.uid == userId;
//          }
//        }
//      }
//    }
// ─────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/progreso_model.dart';
import '../models/estudiante_model.dart';

class FirestoreSyncService {
  final FirebaseFirestore _fs;

  FirestoreSyncService({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  // ── Referencias ───────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _perfilDoc(String uid) =>
      _fs.collection('usuarios').doc(uid);

  CollectionReference<Map<String, dynamic>> _progresoCol(String uid) =>
      _fs.collection('usuarios').doc(uid).collection('progreso');

  // ── Perfil del estudiante ─────────────────────────────────────

  /// Sube (o actualiza) el perfil del estudiante a Firestore.
  /// Usa merge: true para no sobreescribir campos no incluidos.
  Future<void> subirPerfil(EstudianteModel e) async {
    if (e.firebaseUid == null) return;
    await _perfilDoc(e.firebaseUid!).set({
      'nombre':          e.nombre,
      'grado':           e.grado,
      'personaje':       e.personaje,
      'email':           e.email,
      'edad':            e.edad,
      'genero':          e.genero,
      'fecha_registro':  e.fechaRegistro,
    }, SetOptions(merge: true));
  }

  /// Descarga el perfil del estudiante desde Firestore.
  /// Retorna null si el usuario no tiene perfil (usuario completamente nuevo).
  Future<Map<String, dynamic>?> descargarPerfil(String uid) async {
    final doc = await _perfilDoc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  // ── Progreso ─────────────────────────────────────────────────

  /// Sube en batch los registros de progreso a Firestore.
  /// El ID del documento es "{grado}_{materia}_{actividad}" para
  /// garantizar unicidad y permitir merge por actividad.
  Future<void> subirProgreso(String uid, List<ProgresoModel> pendientes) async {
    if (pendientes.isEmpty) return;

    // Firestore permite maximo 500 escrituras por batch.
    const batchSize = 400;
    for (int i = 0; i < pendientes.length; i += batchSize) {
      final lote = pendientes.skip(i).take(batchSize).toList();
      final batch = _fs.batch();
      for (final p in lote) {
        final ref = _progresoCol(uid)
            .doc('${p.grado}_${p.materia}_${p.actividad}');
        batch.set(ref, {
          'grado':      p.grado,
          'materia':    p.materia,
          'actividad':  p.actividad,
          'porcentaje': p.porcentaje,
          'intentos':   p.intentos,
          'ultima_vez': p.ultimaVez ?? DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();
    }
  }

  /// Descarga todo el progreso del usuario desde Firestore.
  Future<List<Map<String, dynamic>>> descargarProgreso(String uid) async {
    final snapshot = await _progresoCol(uid).get();
    return snapshot.docs.map((d) => d.data()).toList();
  }
}
